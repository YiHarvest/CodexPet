#!/usr/bin/env python3
"""一个可拖拽、始终置顶的 Linux 桌面宠物窗口。

使用 GTK3 在 Linux 桌面上显示 Codex v2 宠物精灵动画。
支持鼠标拖拽移动、透明背景、帧动画播放。
"""

import argparse
import json
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk


# Codex v2 精灵表的列数（每行帧数）
COLUMNS = 8
# Codex v2 精灵表的行数（动作数）
ROWS = 11
# 每帧播放间隔（毫秒）
FRAME_MS = 140
FRAME_COUNTS = {0: 6, 1: 8, 2: 8, 3: 4, 4: 5, 5: 8, 6: 6, 7: 6, 8: 6}
IDLE_ROW = 0
# Use the original movement row for every drag direction. Vertical dragging
# deliberately does not switch to a separate animation.
MOVE_ROW = 1
HUG_ROW = 3
SLEEP_COLUMNS = 6
SLEEP_ROWS = 2
SLEEP_FRAME_COUNT = SLEEP_COLUMNS * SLEEP_ROWS
# These are deliberately cycled on ordinary clicks so that every supplied
# expression/action is available without hidden keyboard-only bindings.
CLICK_ACTION_ROWS = (4, 5, 6, 7, 8)
LOOK_ROW_START = 9
LOOK_FRAME_COUNT = 16


class DesktopPet(Gtk.Window):
    """桌面宠物窗口类。

    创建一个透明、可拖拽、始终置顶的窗口，
    用于显示 Codex v2 宠物的精灵动画。

    Attributes:
        sheet: 精灵图 Pixbuf 对象
        frame_width: 单帧宽度（像素）
        frame_height: 单帧高度（像素）
        output_width: 输出显示宽度（缩放后）
        output_height: 输出显示高度（缩放后）
        frame: 当前播放帧索引
        drag_x: 拖拽时的鼠标 X 坐标
        drag_y: 拖拽时的鼠标 Y 坐标
    """

    def __init__(self, pet_dir: Path, scale: float) -> None:
        """初始化桌面宠物窗口。

        Args:
            pet_dir: 宠物资源目录路径，包含 pet.json 和 spritesheet.png
            scale: 显示缩放比例，0.25 到 2.0 之间

        Raises:
            ValueError: 精灵图尺寸不符合 Codex v2 规格（8列 x 11行）
        """
        # A normal tool window is more reliable than POPUP/DOCK windows across
        # X11 window managers. Some compositors briefly map then hide the latter.
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        manifest = json.loads((pet_dir / "pet.json").read_text(encoding="utf-8"))
        self.set_name(manifest.get("displayName", "Codex Pet"))
        # Keep a single source of truth: the packaged PNG contains all of the
        # pet's intended actions, including the hug and vertical movement.
        self.idle_sheet = GdkPixbuf.Pixbuf.new_from_file(str(pet_dir / manifest["spritesheetPath"]))
        if self.idle_sheet.get_width() % COLUMNS or self.idle_sheet.get_height() % ROWS:
            raise ValueError("Expected an 8 by 11 Codex v2 spritesheet")

        self.frame_width = self.idle_sheet.get_width() // COLUMNS
        self.frame_height = self.idle_sheet.get_height() // ROWS
        self.output_width = round(self.frame_width * scale)
        self.output_height = round(self.frame_height * scale)
        self.idle_frame = 0
        self.motion_frame = 0
        self.motion_row = MOVE_ROW
        self.mirror_motion = False
        self.click_action_index = 0
        self.look_index = 0
        self.dragging = False
        self.did_drag = False
        self.activity_running = False
        self.activity_source = None
        self.look_source = None
        # 8.png is a 6x2 sleeping spritesheet, not a standalone animated file.
        sleep_path = pet_dir / "8.png"
        self.sleep_sheet = GdkPixbuf.Pixbuf.new_from_file(str(sleep_path))
        if self.sleep_sheet.get_width() % SLEEP_COLUMNS or self.sleep_sheet.get_height() % SLEEP_ROWS:
            raise ValueError("Expected 8.png to be a 6 by 2 sleep spritesheet")
        self.sleep_frame_width = self.sleep_sheet.get_width() // SLEEP_COLUMNS
        self.sleep_frame_height = self.sleep_sheet.get_height() // SLEEP_ROWS
        self.sleep_frame = 0
        self.sleep_running = False
        self.sleep_source = None
        self.drag_x = 0
        self.drag_y = 0

        self.set_decorated(False)
        self.set_resizable(False)
        # Keep the allocation fixed while transparent frames are replaced.
        # Without this, Gtk.Image briefly reports a zero preferred size after
        # clear(), and the window appears to pulse/scale on every action frame.
        self.set_size_request(self.output_width, self.output_height)
        self.resize(self.output_width, self.output_height)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_type_hint(Gdk.WindowTypeHint.UTILITY)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_app_paintable(True)
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual is not None:
            self.set_visual(visual)

        self.image = Gtk.Image()
        self.image.set_size_request(self.output_width, self.output_height)
        self.image.set_halign(Gtk.Align.CENTER)
        self.image.set_valign(Gtk.Align.CENTER)
        self.add(self.image)
        self.add_events(
            Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.BUTTON_RELEASE_MASK
            | Gdk.EventMask.BUTTON1_MOTION_MASK
            | Gdk.EventMask.ENTER_NOTIFY_MASK
        )
        self.connect("draw", self._clear_background)
        self.connect("button-press-event", self._start_drag)
        self.connect("button-release-event", self._stop_drag)
        self.connect("enter-notify-event", self._start_waiting)
        self.connect("motion-notify-event", self._drag)
        self.connect("destroy", Gtk.main_quit)
        self._render_idle()
        self.show_all()
        # The previous implementation defined _advance_idle but never started
        # it, leaving the smiling idle row frozen on its first frame.
        GLib.timeout_add(FRAME_MS, self._advance_idle)

    @staticmethod
    def _clear_background(widget: Gtk.Widget, context) -> bool:
        """清除窗口背景，实现透明效果。

        Args:
            widget: GTK 窗口组件
            context: Cairo 绘图上下文

        Returns:
            False，表示继续后续绘制流程
        """
        context.set_source_rgba(0, 0, 0, 0)
        context.set_operator(0)  # cairo.OPERATOR_CLEAR, without another dependency
        context.paint()
        context.set_operator(2)  # cairo.OPERATOR_OVER
        return False

    def _render_idle(self) -> None:
        """渲染当前帧到窗口。

        从精灵图中截取当前帧区域，缩放后显示在窗口中。
        Codex v2 精灵表的第一行是会笑的待机动画循环。
        """
        # The first row is the standard idle loop in the Codex v2 sheet.
        source = GdkPixbuf.Pixbuf.new_subpixbuf(
            self.idle_sheet,
            self.idle_frame * self.frame_width,
            IDLE_ROW * self.frame_height,
            self.frame_width,
            self.frame_height,
        )
        self._set_exact_frame(source)

    def _advance_idle(self) -> bool:
        if not self.dragging and not self.activity_running:
            self.idle_frame = (self.idle_frame + 1) % FRAME_COUNTS[IDLE_ROW]
            self._render_idle()
        return True

    def _render_motion(self) -> None:
        source = GdkPixbuf.Pixbuf.new_subpixbuf(
            self.idle_sheet,
            self.motion_frame * self.frame_width,
            self.motion_row * self.frame_height,
            self.frame_width,
            self.frame_height,
        )
        if self.mirror_motion:
            source = source.flip(True)
        # Every cell is already a fixed 192x208 canvas. Rendering it intact
        # avoids alpha-bound cropping, which caused afterimages and apparent
        # scale changes between movement frames.
        self._set_exact_frame(source)

    def _set_exact_frame(self, source: GdkPixbuf.Pixbuf) -> None:
        self.image.set_from_pixbuf(
            source.scale_simple(self.output_width, self.output_height, GdkPixbuf.InterpType.BILINEAR)
        )
        self.queue_draw()

    def _set_contained_frame(self, source: GdkPixbuf.Pixbuf) -> None:
        """Fit a differently sized sprite cell onto the normal fixed canvas."""
        fit_scale = min(self.frame_width / source.get_width(), self.frame_height / source.get_height())
        fitted_width = max(1, round(source.get_width() * fit_scale))
        fitted_height = max(1, round(source.get_height() * fit_scale))
        fitted = source.scale_simple(fitted_width, fitted_height, GdkPixbuf.InterpType.BILINEAR)
        canvas = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, self.frame_width, self.frame_height)
        canvas.fill(0)
        fitted.copy_area(
            0,
            0,
            fitted_width,
            fitted_height,
            canvas,
            (self.frame_width - fitted_width) // 2,
            self.frame_height - fitted_height,
        )
        scaled = canvas.scale_simple(self.output_width, self.output_height, GdkPixbuf.InterpType.BILINEAR)
        self.image.set_from_pixbuf(scaled)
        self.queue_draw()

    def _advance_motion(self) -> bool:
        if not self.dragging:
            return False
        self.motion_frame = (self.motion_frame + 1) % FRAME_COUNTS[self.motion_row]
        self._render_motion()
        return True

    def _advance_activity(self) -> bool:
        self.motion_frame += 1
        if self.motion_frame >= FRAME_COUNTS[self.motion_row]:
            self.activity_running = False
            self.activity_source = None
            self._render_idle()
            return False
        self._render_motion()
        return True

    def _start_activity(self, row: int) -> None:
        if self.dragging or self.activity_running or self.sleep_running:
            return
        self.motion_row = row
        self.mirror_motion = False
        self.motion_frame = 0
        self.activity_running = True
        self._render_motion()
        self.activity_source = GLib.timeout_add(FRAME_MS, self._advance_activity)

    def _start_sleep(self) -> None:
        """Play all 12 frames in the 8.png sleep spritesheet once."""
        if self.dragging:
            return
        if self.activity_source is not None:
            GLib.source_remove(self.activity_source)
            self.activity_source = None
        if self.look_source is not None:
            GLib.source_remove(self.look_source)
            self.look_source = None
        if self.sleep_source is not None:
            GLib.source_remove(self.sleep_source)
            self.sleep_source = None
        self.activity_running = True
        self.sleep_running = True
        self.sleep_frame = 0
        self._render_sleep()
        self.sleep_source = GLib.timeout_add(FRAME_MS, self._advance_sleep)

    def _render_sleep(self) -> None:
        column = self.sleep_frame % SLEEP_COLUMNS
        row = self.sleep_frame // SLEEP_COLUMNS
        source = GdkPixbuf.Pixbuf.new_subpixbuf(
            self.sleep_sheet,
            column * self.sleep_frame_width,
            row * self.sleep_frame_height,
            self.sleep_frame_width,
            self.sleep_frame_height,
        )
        self._set_contained_frame(source)

    def _advance_sleep(self) -> bool:
        if not self.sleep_running:
            return False
        self.sleep_frame += 1
        if self.sleep_frame >= SLEEP_FRAME_COUNT:
            return self._finish_sleep()
        self._render_sleep()
        return True

    def _finish_sleep(self) -> bool:
        self.sleep_running = False
        self.sleep_source = None
        self.activity_running = False
        self._render_idle()
        return False

    def _start_look(self) -> None:
        """Show one of the 16 directional-look cells in PNG rows 9 and 10."""
        if self.dragging or self.activity_running:
            return
        self.motion_row = LOOK_ROW_START + self.look_index // COLUMNS
        self.motion_frame = self.look_index % COLUMNS
        self.look_index = (self.look_index + 1) % LOOK_FRAME_COUNT
        self.mirror_motion = False
        self.activity_running = True
        self._set_exact_frame(
            GdkPixbuf.Pixbuf.new_subpixbuf(
                self.idle_sheet,
                self.motion_frame * self.frame_width,
                self.motion_row * self.frame_height,
                self.frame_width,
                self.frame_height,
            )
        )
        self.look_source = GLib.timeout_add(900, self._finish_look)

    def _finish_look(self) -> bool:
        self.look_source = None
        self.activity_running = False
        self._render_idle()
        return False

    def _start_drag(self, _widget, event) -> bool:
        """记录鼠标按下时的坐标，开始拖拽。

        Args:
            _widget: GTK 窗口组件
            event: 鼠标事件对象

        Returns:
            True，表示事件已处理
        """
        if event.button == 1 and not self.activity_running:
            self.drag_x, self.drag_y = event.x_root, event.y_root
            self.dragging = True
            self.did_drag = False
        elif event.button == 3 and not self.dragging:
            if event.type == Gdk.EventType._2BUTTON_PRESS:
                self._start_sleep()
            else:
                # Keep the single-click hug; a consecutive second right-click
                # interrupts it and starts the sleep spritesheet action.
                self._start_activity(HUG_ROW)
        elif event.button == 2 and event.state & Gdk.ModifierType.SHIFT_MASK:
            self._start_look()
        elif event.button == 2 and not self.dragging:
            self._start_activity(CLICK_ACTION_ROWS[self.click_action_index])
            self.click_action_index = (self.click_action_index + 1) % len(CLICK_ACTION_ROWS)
        return True

    def _stop_drag(self, _widget, event) -> bool:
        if event.button == 1:
            if self.sleep_running or self.activity_running:
                return True
            self.dragging = False
            if self.did_drag:
                self._render_idle()
            else:
                self._start_activity(CLICK_ACTION_ROWS[self.click_action_index])
                self.click_action_index = (self.click_action_index + 1) % len(CLICK_ACTION_ROWS)
        return True

    def _start_waiting(self, _widget, _event) -> bool:
        return False

    def _drag(self, _widget, event) -> bool:
        """处理鼠标拖拽移动窗口。

        Args:
            _widget: GTK 窗口组件
            event: 鼠标事件对象

        Returns:
            True，表示事件已处理
        """
        if self.dragging and event.state & Gdk.ModifierType.BUTTON1_MASK:
            x, y = self.get_position()
            delta_x = event.x_root - self.drag_x
            delta_y = event.y_root - self.drag_y
            # Select a complete, stable action row. This avoids switching rows
            # from tiny pointer jitter, which previously looked like ghosting.
            if abs(delta_x) + abs(delta_y) >= 4:
                if not self.did_drag:
                    self.did_drag = True
                    self.activity_running = False
                    self.motion_frame = 0
                    GLib.timeout_add(FRAME_MS, self._advance_motion)
                self.motion_row = MOVE_ROW
                self.mirror_motion = abs(delta_x) >= abs(delta_y) and delta_x < 0
                self._render_motion()
            self.move(round(x + delta_x), round(y + delta_y))
            self.drag_x, self.drag_y = event.x_root, event.y_root
        return True


def main() -> int:
    """程序入口函数。

    解析命令行参数，创建并运行桌面宠物窗口。

    Returns:
        退出状态码，0 表示正常退出
    """
    parser = argparse.ArgumentParser(description="Show a Codex pet as a Linux desktop overlay.")
    parser.add_argument(
        "--pet", type=Path, default=Path(__file__).resolve().parents[1] / "bubuyier-ref"
    )
    parser.add_argument("--scale", type=float, default=0.75)
    args = parser.parse_args()
    if not 0.25 <= args.scale <= 2:
        parser.error("--scale must be between 0.25 and 2")
    if not (args.pet / "pet.json").is_file():
        parser.error(f"pet.json not found in {args.pet}")
    DesktopPet(args.pet, args.scale)
    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())
