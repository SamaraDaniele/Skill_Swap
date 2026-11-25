<#
.SYNOPSIS
  Draws illustrated (fictional) avatars for the test accounts into
  tool/demo_avatars/teste1.jpg … teste10.jpg.

.DESCRIPTION
  Flat illustrations, not photos of real people. 384×384 JPEG, the same
  size the app uploads (ProfilePhoto.side), so they pass firestore.rules
  (JPEG, at most 100 KiB) and ProfilePhoto.isAcceptable.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File tool/generate_demo_avatars.ps1
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$outDir = Join-Path $PSScriptRoot 'demo_avatars'
New-Item -ItemType Directory -Force $outDir | Out-Null

function C([string]$hex) { [Drawing.ColorTranslator]::FromHtml($hex) }

$avatars = @(
  @{ file = 'teste1'; bg = @('#3A7BD5', '#6D3FC0'); skin = '#C68A5E'; hair = '#2B1D14'; shirt = '#14B8A6'; long = $false }
  @{ file = 'teste2'; bg = @('#F97316', '#EC4899'); skin = '#F1C7A5'; hair = '#7A4A2A'; shirt = '#FB7185'; long = $true }
  @{ file = 'teste3'; bg = @('#16A34A', '#0D9488'); skin = '#7B4A2E'; hair = '#111111'; shirt = '#EAB308'; long = $false }
  @{ file = 'teste4'; bg = @('#8B5CF6', '#D946EF'); skin = '#A86F4C'; hair = '#1A1110'; shirt = '#C4B5FD'; long = $true }
  @{ file = 'teste5'; bg = @('#F59E0B', '#EA580C'); skin = '#F3D2B5'; hair = '#B7843F'; shirt = '#1E3A8A'; long = $false }
  @{ file = 'teste6'; bg = @('#0EA5E9', '#1E293B'); skin = '#D9A47E'; hair = '#3B2A1E'; shirt = '#1F2937'; long = $false }
  @{ file = 'teste7'; bg = @('#06B6D4', '#3B82F6'); skin = '#E8B796'; hair = '#C2410C'; shirt = '#FDE047'; long = $true }
  @{ file = 'teste8'; bg = @('#65A30D', '#15803D'); skin = '#B07650'; hair = '#2A1A10'; shirt = '#F97316'; long = $false }
  @{ file = 'teste9'; bg = @('#E11D48', '#7C3AED'); skin = '#8D5A3B'; hair = '#0F0A08'; shirt = '#F0ABFC'; long = $true }
  @{ file = 'teste10'; bg = @('#475569', '#0F766E'); skin = '#EFC9A8'; hair = '#5B3A1F'; shirt = '#38BDF8'; long = $false }
)

$size = 384
$codec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$params = New-Object Drawing.Imaging.EncoderParameters 1
$params.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality, [long]85)

foreach ($a in $avatars) {
  $bmp = New-Object Drawing.Bitmap $size, $size
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'

  $rect = New-Object Drawing.Rectangle 0, 0, $size, $size
  $bg = New-Object Drawing.Drawing2D.LinearGradientBrush $rect, (C $a.bg[0]), (C $a.bg[1]), 45
  $g.FillRectangle($bg, $rect)

  $skin = New-Object Drawing.SolidBrush (C $a.skin)
  $hair = New-Object Drawing.SolidBrush (C $a.hair)
  $shirt = New-Object Drawing.SolidBrush (C $a.shirt)
  $dark = New-Object Drawing.SolidBrush (C '#1F1A17')

  # Long hair sits behind the head and shoulders.
  if ($a.long) { $g.FillEllipse($hair, 104, 88, 176, 236) }
  # Shoulders and neck.
  $g.FillEllipse($shirt, 56, 268, 272, 220)
  $g.FillRectangle($skin, 168, 220, 48, 64)
  # Head.
  $g.FillEllipse($skin, 128, 104, 128, 148)
  # Hair on top.
  $g.FillPie($hair, 120, 92, 144, 104, 180, 180)
  if (-not $a.long) { $g.FillEllipse($hair, 124, 104, 30, 52); $g.FillEllipse($hair, 230, 104, 30, 52) }
  # Face.
  $g.FillEllipse($dark, 160, 168, 12, 14)
  $g.FillEllipse($dark, 212, 168, 12, 14)
  $pen = New-Object Drawing.Pen (C '#1F1A17'), 4
  $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
  $g.DrawArc($pen, 170, 186, 44, 30, 20, 140)

  $path = Join-Path $outDir "$($a.file).jpg"
  $bmp.Save($path, $codec, $params)
  $g.Dispose(); $bmp.Dispose()
  Write-Host ("{0} ({1:N0} bytes)" -f $path, (Get-Item $path).Length)
}
