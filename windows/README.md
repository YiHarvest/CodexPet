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

## 鼠标动作

| 操作 | 动作 |
| --- | --- |
| 待机 | 循环播放 `spritesheet.png` 第 1 行的笑脸动画 |
| 任意方向拖动 | 播放第 2 行的原始移动动画 |
| 连续右键两次 | 播放 `8.png` 的 12 帧睡觉精灵图，然后回到待机 |
| 左键单击 | 轮流播放第 5–9 行的所有表情和互动 |
| 右键单击 | 播放第 4 行的抱一抱 |
| 中键单击 | 切换到下一种表情和互动 |
