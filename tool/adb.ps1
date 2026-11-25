<#
.SYNOPSIS
  Small adb helper for manual UI checks on the emulator.
.EXAMPLE
  ./tool/adb.ps1 shot home              # saves build/screens/home.png
  ./tool/adb.ps1 tap 540 1200
  ./tool/adb.ps1 tapText 'Create account'   # taps the element whose label contains the text
  ./tool/adb.ps1 text 'teste1@gmail.com'
  ./tool/adb.ps1 secret test1            # types the password stored in tool/test_accounts.local.json
  ./tool/adb.ps1 key BACK
  ./tool/adb.ps1 labels                  # lists on-screen accessibility labels
#>
param(
  [Parameter(Mandatory)][ValidateSet('shot', 'tap', 'tapText', 'text', 'fill', 'secret', 'key', 'swipe', 'labels')]
  [string]$Action,
  [Parameter(ValueFromRemainingArguments)][string[]]$Rest = @()
)
$ErrorActionPreference = 'Stop'
$adb = 'C:\src\android-sdk\platform-tools\adb.exe'
$root = Split-Path $PSScriptRoot -Parent
$accountsFile = Join-Path $PSScriptRoot 'test_accounts.local.json'

function Get-UiNodes {
  $tmp = Join-Path $env:TEMP 'skill_swap_ui.xml'
  & $adb shell uiautomator dump /sdcard/ui.xml | Out-Null
  & $adb pull /sdcard/ui.xml $tmp | Out-Null
  [xml]$xml = Get-Content $tmp -Raw -Encoding UTF8
  $xml.SelectNodes('//node')
}

function Get-Center([string]$bounds) {
  $m = [regex]::Match($bounds, '\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
  $x = ([int]$m.Groups[1].Value + [int]$m.Groups[3].Value) / 2
  $y = ([int]$m.Groups[2].Value + [int]$m.Groups[4].Value) / 2
  return @([int]$x, [int]$y)
}

# Flutter's text input drops characters when adb types a long string at once,
# so send small chunks with a pause between them.
function Send-Text([string]$value) {
  for ($i = 0; $i -lt $value.Length; $i += 3) {
    $chunk = $value.Substring($i, [Math]::Min(3, $value.Length - $i))
    & $adb shell input text ($chunk -replace ' ', '%s')
    Start-Sleep -Milliseconds 250
  }
}

function Get-Label($node) {
  ((($node.text, $node.'content-desc', $node.hint) | Where-Object { $_ }) -join ' | ') -replace '\s+', ' '
}

switch ($Action) {
  'shot' {
    $name = if ($Rest.Count) { $Rest[0] } else { 'screen' }
    $dir = Join-Path $root 'build\screens'
    New-Item -ItemType Directory -Force $dir | Out-Null
    & $adb shell screencap -p "/sdcard/$name.png"
    & $adb pull "/sdcard/$name.png" (Join-Path $dir "$name.png") | Out-Null
    & $adb shell rm "/sdcard/$name.png"
    Write-Host "saved build/screens/$name.png"
  }
  'tap' { & $adb shell input tap $Rest[0] $Rest[1] }
  'tapText' {
    $needle = $Rest[0]
    $index = if ($Rest.Count -gt 1) { [int]$Rest[1] } else { 0 }
    $hits = @(Get-UiNodes | Where-Object { (Get-Label $_) -like "*$needle*" })
    if ($hits.Count -le $index) { throw "No element labelled '$needle' (found $($hits.Count))." }
    $center = Get-Center $hits[$index].bounds
    & $adb shell input tap $center[0] $center[1]
    Write-Host "tapped '$needle' at $($center -join ',')"
  }
  'labels' {
    Get-UiNodes | ForEach-Object {
      $label = Get-Label $_
      if ($label) { '{0,-28} {1}' -f $_.bounds, ($label -replace '\s+', ' ') }
    }
  }
  'text' { Send-Text $Rest[0] }
  'fill' {
    # fill <field label> <value>: focus, wait for the keyboard, clear, type, verify.
    $field = $Rest[0]; $value = $Rest[1]
    $find = { @(Get-UiNodes | Where-Object { $_.'content-desc' -like "*$field*" -or $_.hint -like "*$field*" })[0] }
    $node = & $find
    if (-not $node) { throw "Field '$field' not found." }
    $center = Get-Center $node.bounds
    & $adb shell input tap $center[0] $center[1]
    Start-Sleep -Milliseconds 1500
    $current = [string]$node.text
    if ($current.Length) {
      & $adb shell input keyevent KEYCODE_MOVE_END
      & $adb shell input keyevent @(1..($current.Length + 2) | ForEach-Object { 67 })
      Start-Sleep -Milliseconds 500
    }
    Send-Text $value
    Start-Sleep -Milliseconds 1000
    $after = [string](& $find).text
    if ($after -ne $value) { throw "Field '$field' has '$after', expected '$value'." }
    Write-Host "filled '$field'"
  }
  'secret' {
    $accounts = Get-Content $accountsFile -Raw | ConvertFrom-Json
    $password = $accounts.($Rest[0]).password
    if (-not $password) { throw "No password for '$($Rest[0])'." }
    Start-Sleep -Milliseconds 1500  # let the keyboard open after focusing the field
    Send-Text $password
    Write-Host "typed password for $($Rest[0])"
  }
  'key' { & $adb shell input keyevent "KEYCODE_$($Rest[0])" }
  'swipe' { & $adb shell input swipe $Rest[0] $Rest[1] $Rest[2] $Rest[3] $Rest[4] }
}
