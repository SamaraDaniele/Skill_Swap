<#
.SYNOPSIS
  Installs the Android NDK required by the Android Gradle plugin, directly
  from Google's official repository (same archive sdkmanager downloads).
#>
param(
  [string]$Sdk = 'C:\src\android-sdk',
  [string]$Version = '28.2.13676358',
  [string]$Release = 'r28c'
)
$ErrorActionPreference = 'Stop'
$target = Join-Path $Sdk "ndk\$Version"
# clang.exe is among the last files extracted; checking it catches partial installs.
$clang = Join-Path $target 'toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe'
if ((Test-Path (Join-Path $target 'source.properties')) -and (Test-Path $clang)) {
  Write-Host "NDK $Version already installed." -ForegroundColor Green
  return
}
if (Test-Path $target) {
  Write-Host "==> Removing incomplete NDK at $target" -ForegroundColor Yellow
  Remove-Item $target -Recurse -Force
}

$work = Join-Path $env:TEMP "ndk-$Version"
New-Item -ItemType Directory -Force $work | Out-Null
$zip = Join-Path $work "android-ndk-$Release-windows.zip"
$url = "https://dl.google.com/android/repository/android-ndk-$Release-windows.zip"

Write-Host "==> Downloading $url (~700 MB, no progress bar)" -ForegroundColor Cyan
# Silent: a progress bar can block on slow/hidden terminals.
curl.exe -sS -L --fail --retry 3 -o $zip $url
if ($LASTEXITCODE) { throw 'Download failed.' }

Write-Host '==> Extracting (a few minutes)' -ForegroundColor Cyan
tar.exe -xf $zip -C $work
if ($LASTEXITCODE) { throw 'Extraction failed.' }

$extracted = Join-Path $work "android-ndk-$Release"
$props = Get-Content (Join-Path $extracted 'source.properties') -Raw
if ($props -notmatch [regex]::Escape("Pkg.Revision = $Version")) {
  throw "Archive revision does not match $Version."
}

New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
Move-Item $extracted $target
Remove-Item $work -Recurse -Force
Write-Host "==> NDK $Version installed at $target" -ForegroundColor Green
