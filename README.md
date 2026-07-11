# BubuYier Codex Pet

这是一个 Codex v2 宠物包，并提供了 Linux 与 Windows 的独立桌面悬浮窗。
悬浮窗不修改 OpenAI 的 Codex 文件，因此 Codex / VS Code 更新后仍可使用。

## 先说明：不同 Codex 版本的能力

| 使用方式 | 自定义宠物包 | 显示在桌面 |
| --- | --- | --- |
| Codex Desktop | 可从 `~/.codex/pets/` 或 `%USERPROFILE%\.codex\pets\` 读取 | 使用本项目对应系统的桌面启动器 |
| Codex CLI | 可安装宠物包，但 CLI 本身不显示图形 | 用 `codex-with-pet` 包装命令 |
| VS Code Codex 插件 | 可安装宠物包，但插件内没有悬浮窗入口 | 用 VS Code 任务启动外部悬浮窗 |

## Linux

### 安装 Codex 宠物包

```bash
./linux.sh
```

它会复制到 `~/.codex/pets/bubuyier-ref`。

### Codex Desktop / 直接显示桌面宠物

```bash
./linux/codex-desktop-pet
# 或安装应用启动器后，在系统应用菜单中打开 Codex Pet
./linux/install-desktop-launcher.sh
```

### Codex CLI

```bash
# 正常使用：显示、隐藏与切换
./linux/codex-pet show
./linux/codex-pet hide
./linux/codex-pet toggle

# 让宠物在本次 Codex CLI 会话期间显示
./linux/codex-with-pet
```

### VS Code Codex 插件

将 `linux/vscode/tasks.json` 复制或合并到项目的 `.vscode/tasks.json`；然后按
`Ctrl+Shift+P`，运行 `Tasks: Run Task`，选择 `Codex Pet: Show` 或
`Codex Pet: Hide`。

Linux 悬浮窗依赖 GTK 3（Ubuntu/Debian：`sudo apt install python3-gi gir1.2-gtk-3.0`），
当前实现支持 X11。

详见 [linux/README.md](linux/README.md)。

## Windows

### 安装 Codex 宠物包

```powershell
.\install.ps1
```

它会复制到 `%USERPROFILE%\.codex\pets\bubuyier-ref`。

### Codex Desktop / 直接显示桌面宠物

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\codex-desktop-pet.ps1

# 可选：创建双击启动的桌面快捷方式
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\install-desktop-shortcut.ps1
```

### Codex CLI

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\codex-pet.ps1 show
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\codex-pet.ps1 hide

# 让宠物在本次 Codex CLI 会话期间显示
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\codex-with-pet.ps1
```

### VS Code Codex 插件

将 `windows\vscode\tasks.json` 复制或合并到项目的 `.vscode\tasks.json`；然后按
`Ctrl+Shift+P`，运行 `Tasks: Run Task`，选择 `Codex Pet: Show` 或
`Codex Pet: Hide`。

详见 [windows/README.md](windows/README.md)。

## 目录

- `pets/bubuyier-ref/codex-v2/`：Codex 安装包（`pet.json` 与 PNG 精灵图）
- `pets/bubuyier-ref/source/`：原始 WebP 精灵图；Linux 拖动时的动作动画使用该资源
- `pets/bubuyier-ref/states/`：Codex 工作状态动画（思考、工作、等待、完成）
- `bubuyier-ref`：兼容旧路径的符号链接，指向 `pets/bubuyier-ref/codex-v2/`，不重复存放图片
- `linux/`：Linux 桌面、CLI 与 VS Code 启动入口
- `windows/`：Windows 桌面、CLI 与 VS Code 启动入口
- `install.ps1`、`linux.sh`：仅安装宠物包到 Codex 配置目录
