param(
    [ValidateRange(0.25, 2.0)]
    [double]$Scale = 0.75
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$root = Split-Path -Parent $PSScriptRoot
$petRoot = Join-Path $root 'bubuyier-ref'
$manifest = Get-Content (Join-Path $petRoot 'pet.json') -Raw | ConvertFrom-Json
$spritePath = Join-Path $petRoot $manifest.spritesheetPath
if (-not (Test-Path -LiteralPath $spritePath)) { throw "Spritesheet not found: $spritePath" }

$sheet = [Windows.Media.Imaging.BitmapImage]::new()
$sheet.BeginInit()
$sheet.UriSource = [Uri]$spritePath
$sheet.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$sheet.EndInit()
$sheet.Freeze()

$sleepPath = Join-Path $petRoot '8.png'
if (-not (Test-Path -LiteralPath $sleepPath)) { throw "Sleep spritesheet not found: $sleepPath" }
$sleepSource = [Windows.Media.Imaging.BitmapImage]::new()
$sleepSource.BeginInit()
$sleepSource.UriSource = [Uri]$sleepPath
$sleepSource.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$sleepSource.EndInit()

$sleepSource.Freeze()
$sleepSheet = $sleepSource

$columns = 8
$rows = 11
$frameWidth = [int]($sheet.PixelWidth / $columns)
$frameHeight = [int]($sheet.PixelHeight / $rows)
$sleepColumns = 6
$sleepRows = 2
if ($sleepSheet.PixelWidth % $sleepColumns -ne 0 -or $sleepSheet.PixelHeight % $sleepRows -ne 0) {
    throw 'Expected 8.png to be a 6 by 2 sleep spritesheet'
}
$sleepFrameWidth = [int]($sleepSheet.PixelWidth / $sleepColumns)
$sleepFrameHeight = [int]($sleepSheet.PixelHeight / $sleepRows)
$sleepFrameCount = $sleepColumns * $sleepRows
$width = [Math]::Round($frameWidth * $Scale)
$height = [Math]::Round($frameHeight * $Scale)

$window = [Windows.Window]::new()
$window.Title = $manifest.displayName
$window.Width = $width
$window.Height = $height
$window.WindowStyle = [Windows.WindowStyle]::None
$window.AllowsTransparency = $true
$window.Background = [Windows.Media.Brushes]::Transparent
$window.Topmost = $true
$window.ShowInTaskbar = $false
$window.ResizeMode = [Windows.ResizeMode]::NoResize

$image = [Windows.Controls.Image]::new()
$image.Width = $width
$image.Height = $height
$image.Stretch = [Windows.Media.Stretch]::Uniform
$image.HorizontalAlignment = [Windows.HorizontalAlignment]::Center
$image.VerticalAlignment = [Windows.VerticalAlignment]::Center
$window.Content = $image

$frameCounts = @(6, 8, 8, 4, 5, 8, 6, 6, 6)
$clickActionRows = @(4, 5, 6, 7, 8)
$state = [PSCustomObject]@{
    Frame = 0
    ActionRow = 0
    ActionRunning = $false
    SleepRunning = $false
    SleepFrame = 0
    ClickActionIndex = 0
    Dragging = $false
    DidDrag = $false
    LastX = 0.0
    LastY = 0.0
}
$renderFrame = {
    $rect = [Windows.Int32Rect]::new($state.Frame * $frameWidth, $state.ActionRow * $frameHeight, $frameWidth, $frameHeight)
    $crop = [Windows.Media.Imaging.CroppedBitmap]::new($sheet, $rect)
    $crop.Freeze()
    $image.Source = $crop
}
$renderSleepFrame = {
    $column = $state.SleepFrame % $sleepColumns
    $row = [int]($state.SleepFrame / $sleepColumns)
    $rect = [Windows.Int32Rect]::new($column * $sleepFrameWidth, $row * $sleepFrameHeight, $sleepFrameWidth, $sleepFrameHeight)
    $crop = [Windows.Media.Imaging.CroppedBitmap]::new($sleepSheet, $rect)
    $crop.Freeze()
    $image.Source = $crop
}
& $renderFrame

$startAction = {
    param([int]$row)
    if ($state.Dragging -or $state.SleepRunning -or $state.ActionRunning) { return }
    $state.ActionRow = $row
    $state.Frame = 0
    $state.ActionRunning = $true
    & $renderFrame
}
$startSleep = {
    if ($state.Dragging) { return }
    $state.ActionRunning = $false
    $state.SleepRunning = $true
    $state.SleepFrame = 0
    & $renderSleepFrame
}

$timer = [Windows.Threading.DispatcherTimer]::new()
$timer.Interval = [TimeSpan]::FromMilliseconds(140)
$timer.Add_Tick({
    if ($state.SleepRunning) {
        $state.SleepFrame++
        if ($state.SleepFrame -ge $sleepFrameCount) {
            $state.SleepRunning = $false
            $state.ActionRow = 0
            $state.Frame = 0
            & $renderFrame
        } else {
            & $renderSleepFrame
        }
        return
    }
    $state.Frame++
    if ($state.Frame -ge $frameCounts[$state.ActionRow]) {
        $state.Frame = 0
        if (-not $state.Dragging -and $state.ActionRunning) {
            $state.ActionRow = 0
            $state.ActionRunning = $false
        }
    }
    & $renderFrame
})
$window.Add_Loaded({ $timer.Start() })
$window.Add_Closed({ $timer.Stop() })

$window.Add_MouseLeftButtonDown({
    param($sender, $event)
    if ($state.ActionRunning -or $state.SleepRunning) { return }
    $point = $window.PointToScreen($event.GetPosition($window))
    $state.LastX = $point.X
    $state.LastY = $point.Y
    $state.Dragging = $true
    $state.DidDrag = $false
    [void]$window.CaptureMouse()
    $event.Handled = $true
})
$window.Add_MouseMove({
    param($sender, $event)
    if (-not $state.Dragging -or $event.LeftButton -ne [Windows.Input.MouseButtonState]::Pressed) { return }
    $point = $window.PointToScreen($event.GetPosition($window))
    $deltaX = $point.X - $state.LastX
    $deltaY = $point.Y - $state.LastY
    if ([Math]::Abs($deltaX) + [Math]::Abs($deltaY) -ge 4) {
        $state.DidDrag = $true
        # Use the original movement row for every drag direction; vertical
        # dragging deliberately has no separate animation.
        $state.ActionRow = 1
        $state.Frame = 0
    }
    $window.Left += $deltaX
    $window.Top += $deltaY
    $state.LastX = $point.X
    $state.LastY = $point.Y
    & $renderFrame
})
$window.Add_MouseLeftButtonUp({
    param($sender, $event)
    if (-not $state.Dragging) { return }
    $state.Dragging = $false
    $window.ReleaseMouseCapture()
    if ($state.DidDrag) {
        $state.ActionRow = 0
        $state.Frame = 0
    } else {
        & $startAction $clickActionRows[$state.ClickActionIndex]
        $state.ClickActionIndex = ($state.ClickActionIndex + 1) % $clickActionRows.Count
    }
    $event.Handled = $true
})
$window.Add_MouseRightButtonDown({
    param($sender, $event)
    if ($event.ClickCount -ge 2) {
        & $startSleep
    } else {
        # Keep the single-click hug. The second right-click starts sleep.
        & $startAction 3
    }
    $event.Handled = $true
})
$window.Add_MouseDown({
    param($sender, $event)
    if ($event.ChangedButton -ne [Windows.Input.MouseButton]::MiddleButton) { return }
    & $startAction $clickActionRows[$state.ClickActionIndex]
    $state.ClickActionIndex = ($state.ClickActionIndex + 1) % $clickActionRows.Count
    $event.Handled = $true
})

[void]$window.ShowDialog()
