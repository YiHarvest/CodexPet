# Linux 使用说明

这个目录实现的是独立的 GTK 桌面悬浮窗：透明、置顶、可拖拽。它不修改 Codex Desktop、
Codex CLI 或 VS Code 的安装文件，因此更新这些程序后不受影响。

## Codex Desktop / 直接启动

```bash
./linux/codex-desktop-pet
```

可安装到系统应用菜单：

```bash
./linux/install-desktop-launcher.sh
```

## Codex CLI

```bash
# 手动控制
./linux/codex-pet show
./linux/codex-pet hide
./linux/codex-pet toggle
./linux/codex-pet status

# 运行 Codex CLI 的同时显示；命令结束会自动收起
./linux/codex-with-pet

```

可把参数继续传给 CLI，例如：

```bash
./linux/codex-with-pet --help
```

## VS Code Codex 插件

把 `linux/vscode/tasks.json` 复制或合并到工作区的 `.vscode/tasks.json`。在 VS Code 中按
`Ctrl+Shift+P`，执行 `Tasks: Run Task`，再选择 `Codex Pet: Show` 或
`Codex Pet: Hide`。这会从 VS Code 启动同一个桌面悬浮窗。

## 依赖与限制

需要 Python 3、PyGObject 和 GTK 3。Ubuntu / Debian 可执行：

```bash
sudo apt install python3-gi gir1.2-gtk-3.0
```

当前版本面向 X11。待机使用 PNG 的稳定首帧；拖动时使用 WebP 跑动动作。

| 操作 | 动作 |
| --- | --- |
| 水平拖动 | 向左或向右跑 |
| 垂直拖动 | 通用跑动 |
| 单击（未拖动） | `8.webp` 思考 / 休息 |
| 右键单击 | `9.webp` 陪伴工作 |
| 中键单击 | `10.webp` 陪伴等待 |
| Shift + 单击 | `7.webp` 完成 / 庆祝 |

## 四张补充图片的触发设计

VS Code Codex 插件并未公开稳定的工作生命周期，不能把图片伪装成自动的“思考/完成”状态。
因此四张图片采用短暂手势动作：每次播放约 2.6 秒后回到待机，不会长时间停在某一张图上。
这比不可靠地猜测插件状态更符合实际使用。
