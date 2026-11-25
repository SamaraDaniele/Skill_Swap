<#
.SYNOPSIS
  Starts the Android emulator (software rendering) and runs the app on it.
.DESCRIPTION
  The host GPU driver on this machine does not expose an OpenGL core profile
  to the Android emulator, so hardware rendering fails ("Could not start
  renderer"). SwiftShader (software) rendering works everywhere.
.EXAMPLE
  ./tool/run_android.ps1
  ./tool/run_android.ps1 -Avd Pixel_8_API_36 -ColdBoot
  ./tool/run_android.ps1 -NoAudio   # emulator without sound output
#>
param(
  [string]$Avd = 'Pixel_8_API_36',
  [string]$Sdk = 'C:\src\android-sdk',
  [switch]$ColdBoot,
  # Sound is on by default (post videos have audio); -NoAudio turns it off.
  [switch]$NoAudio
)
$ErrorActionPreference = 'Stop'
$adb = Join-Path $Sdk 'platform-tools\adb.exe'
$emulator = Join-Path $Sdk 'emulator\emulator.exe'
$projectRoot = Split-Path $PSScriptRoot -Parent

function Get-BootedSerial {
  $lines = & $adb devices | Select-String '^(emulator-\d+)\s+device$'
  foreach ($line in $lines) {
    $serial = $line.Matches[0].Groups[1].Value
    if ((& $adb -s $serial shell getprop sys.boot_completed 2>$null) -match '1') {
      return $serial
    }
  }
  return $null
}

# The Android Gradle plugin needs an NDK; its auto-install (sdkmanager)
# fails on this machine, so install it up front.
& (Join-Path $PSScriptRoot 'install_ndk.ps1') -Sdk $Sdk

& $adb start-server | Out-Null
$serial = Get-BootedSerial

if (-not $serial) {
  Write-Host '==> Stopping stale emulator processes' -ForegroundColor Cyan
  Get-Process qemu-system-x86_64, emulator -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  Get-ChildItem "$env:USERPROFILE\.android\avd\$Avd.avd" -Filter '*.lock' -Recurse -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

  Write-Host "==> Starting emulator $Avd (software rendering)" -ForegroundColor Cyan
  # 6 cores: software rendering is CPU-heavy and starves the audio (choppy
  # sound with the AVD's default 4).
  $emuArgs = @('-avd', $Avd, '-gpu', 'swiftshader_indirect', '-cores', '6')
  if ($NoAudio) { $emuArgs += '-no-audio' }
  if ($ColdBoot) { $emuArgs += '-no-snapshot-load' }
  Start-Process -FilePath $emulator -ArgumentList $emuArgs -WindowStyle Minimized

  Write-Host '==> Waiting for Android to boot (can take a few minutes)' -ForegroundColor Cyan
  $deadline = (Get-Date).AddMinutes(8)
  while (-not $serial) {
    if ((Get-Date) -gt $deadline) { throw 'Emulator did not boot within 8 minutes.' }
    Start-Sleep -Seconds 5
    $serial = Get-BootedSerial
  }
}

Write-Host "==> Emulator ready: $serial" -ForegroundColor Green
# With the screen asleep Android treats the app as background and blocks its
# network (Firestore: "Unable to resolve host"). Wake it, unlock it and keep
# it on. The emulator reports "not plugged in", so `svc power stayon` has no
# effect; a very long screen-off timeout does.
& $adb -s $serial shell input keyevent KEYCODE_WAKEUP
& $adb -s $serial shell wm dismiss-keyguard
& $adb -s $serial shell settings put system screen_off_timeout 2147483647

# Android build tools (aapt) cannot read non-ASCII paths such as
# "Área de Trabalho" ("Illegal byte sequence"). In that case build through a
# temporary junction with an ASCII path that points at the same folder. It
# must stay on the same drive as the pub cache: Kotlin incremental builds fail
# when sources span drives (so `subst` drive letters do not work).
$runRoot = $projectRoot
$createdLink = $null
if ($projectRoot -match '[^\x20-\x7E]') {
  $workspace = Split-Path $projectRoot -Parent
  $appFolder = Split-Path $projectRoot -Leaf
  $link = Join-Path ([System.IO.Path]::GetTempPath()) 'skill_swap_build'
  $existing = Get-Item $link -Force -ErrorAction SilentlyContinue
  # The Gradle daemon keeps working inside the link after a build, so it may
  # not be removable; reuse it whenever it already points at this folder.
  $reusable = $existing -and $existing.LinkType -eq 'Junction' -and
    (@($existing.Target)[0].TrimEnd('\') -eq $workspace.TrimEnd('\'))
  if ($link -match '[^\x20-\x7E]') {
    Write-Warning 'Temp folder path has accents; building from the project path.'
  } elseif ($reusable) {
    $runRoot = Join-Path $link $appFolder
  } else {
    if ($existing -and $existing.LinkType -eq 'Junction') {
      # A link to another copy: rmdir removes only the link itself.
      cmd /c rmdir "$link" | Out-Null
    }
    if (Test-Path $link) {
      Write-Warning "Could not reuse $link; building from the project path."
    } else {
      New-Item -ItemType Junction -Path $link -Target $workspace | Out-Null
      $createdLink = $link
      $runRoot = Join-Path $link $appFolder
    }
  }
  if ($runRoot -ne $projectRoot) {
    Write-Host "==> Building from $runRoot (path without accents)" -ForegroundColor Cyan
  }
}

Push-Location $runRoot
try {
  # SwiftShader (the emulator's software GPU) crashes the emulator process
  # (qemu access violation in JIT code) when compiling some Impeller shaders,
  # e.g. the sign-in screen's gradients. Skia is stable there; real devices
  # keep Impeller.
  flutter run -d $serial --no-enable-impeller
} finally {
  Pop-Location
  # rmdir on a junction deletes the link only, never the project files.
  if ($createdLink) { cmd /c rmdir "$createdLink" | Out-Null }
}
