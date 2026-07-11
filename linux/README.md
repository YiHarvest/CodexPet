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

当前版本面向 X11。待机和常规互动使用 `bubuyier-ref/spritesheet.png` 的动作帧；
`bubuyier-ref/8.png` 是 6×2 的睡觉精灵图动作，不会被用作待机。

| 操作 | 动作 |
| --- | --- |
| 任意方向拖动 | 精灵图第 2 行的原始移动动作（向左时镜像） |
| 单击（未拖动） | 依次播放精灵图第 5–9 行的所有表情/互动动作 |
| 右键单击 | 精灵图第 4 行的抱一抱 |
| 连续右键两次 | 播放 `8.png` 的 12 帧睡觉精灵图，然后回到笑脸待机 |
| 中键单击 | 与单击相同，立即切换到下一种表情/互动动作 |
| Shift + 中键单击 | 循环显示 PNG 第 10、11 行的 16 个“看向鼠标”方向姿态 |

每个非待机动作会完整播放一遍后自动回到待机。
