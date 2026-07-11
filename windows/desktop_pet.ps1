param(
    [ValidateRange(0.25, 2.0)]
    [double]$Scale = 0.75,
    [switch]$Animate
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$root = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content (Join-Path $root 'pets\bubuyier-ref\codex-v2\pet.json') -Raw | ConvertFrom-Json
$spritePath = Join-Path $root "pets\bubuyier-ref\codex-v2\$($manifest.spritesheetPath)"
if (-not (Test-Path -LiteralPath $spritePath)) { throw "Spritesheet not found: $spritePath" }

$sheet = [Windows.Media.Imaging.BitmapImage]::new()
$sheet.BeginInit()
$sheet.UriSource = [Uri]$spritePath
$sheet.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$sheet.EndInit()
$sheet.Freeze()

$columns = 8
$rows = 11
$frameWidth = [int]($sheet.PixelWidth / $columns)
$frameHeight = [int]($sheet.PixelHeight / $rows)
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
$window.Content = $image

$frame = 0
$renderFrame = {
    $rect = [Windows.Int32Rect]::new($frame * $frameWidth, 0, $frameWidth, $frameHeight)
    $crop = [Windows.Media.Imaging.CroppedBitmap]::new($sheet, $rect)
    $crop.Freeze()
    $image.Source = $crop
}
& $renderFrame

if ($Animate) {
    $timer = [Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromMilliseconds(140)
    $timer.Add_Tick({ $frame = ($frame + 1) % $columns; & $renderFrame })
    $window.Add_Loaded({ $timer.Start() })
    $window.Add_Closed({ $timer.Stop() })
}
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

[void]$window.ShowDialog()
