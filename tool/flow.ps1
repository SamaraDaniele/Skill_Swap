<#
.SYNOPSIS
  Scripted manual-test steps on the emulator, driven through tool/adb.ps1.
.EXAMPLE
  ./tool/flow.ps1 signIn test1
  ./tool/flow.ps1 signIn test2
#>
param(
  [Parameter(Mandatory)][ValidateSet('signUp', 'signIn')][string]$Step,
  [Parameter(Mandatory)][string]$Account,
  [ValidateSet('en', 'pt')][string]$Lang = 'en'
)
$ErrorActionPreference = 'Stop'
$adbHelper = Join-Path $PSScriptRoot 'adb.ps1'
$accounts = Get-Content (Join-Path $PSScriptRoot 'test_accounts.local.json') -Raw | ConvertFrom-Json
$acc = $accounts.$Account

$labels = @{
  en = @{ toSignUp = 'Create an account'; email = 'Email'; password = 'Password'; signUp = 'Create account'; signIn = 'Sign in' }
  pt = @{ toSignUp = 'Crie uma conta'; email = 'E-mail'; password = 'Senha'; signUp = 'Criar conta'; signIn = 'Entrar' }
}[$Lang]

function Adb { & $adbHelper @args }

if ($Step -eq 'signUp') {
  Adb tapText $labels.toSignUp
  Start-Sleep -Milliseconds 600
}
Adb fill $labels.email $acc.email
Adb tapText $labels.password
Adb secret $Account
Adb key BACK
Start-Sleep -Milliseconds 600
Adb tapText ($(if ($Step -eq 'signUp') { $labels.signUp } else { $labels.signIn }))
Start-Sleep -Seconds 4
Adb shot "$($Step)_$Account"
