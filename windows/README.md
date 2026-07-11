# Windows 使用说明

所有脚本均使用透明、置顶、可拖拽的 WPF 窗口；不修改 OpenAI 的 Codex 插件文件。

```powershell
# 显示或隐藏宠物
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\codex-pet.ps1 show
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\codex-pet.ps1 hide

# 使用 Codex CLI；CLI 结束时宠物会自动隐藏
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\codex-with-pet.ps1

# 创建可双击启动的桌面快捷方式
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\install-desktop-shortcut.ps1
```

VS Code：将 `windows\vscode\tasks.json` 复制或合并到
`.vscode\tasks.json`，然后运行 `Tasks: Run Task`，选择 `Codex Pet: Show`
或 `Codex Pet: Hide`。
