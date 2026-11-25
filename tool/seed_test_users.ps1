<#
.SYNOPSIS
  Creates (or refreshes) the 20 test accounts teste1@gmail.com … teste20@gmail.com
  with complete profiles (photo, name, bio, skills) and some interactions,
  so the whole flow can be tried in the app.

.DESCRIPTION
  Each person is a regular account: signed up with Firebase Auth (email /
  password) and written to Firestore with their own ID token, so every write
  goes through firestore.rules exactly like the app (no admin access).

  Per person: consent (18+, terms v1) on first run, then the public profile
  with an avatar from tool/demo_avatars: teste1-10 are illustrations (see
  generate_demo_avatars.ps1); teste11-20 are AI-generated faces of people who
  do not exist (thispersondoesnotexist.com), 384x384 JPEG under 48 KiB.
  Accounts missing from the credentials file are skipped. Then:
    - Camila (teste2), Bruno (teste3), Larissa (teste7), Rafael (teste8),
      Juliana (teste9) and Thiago (teste10) already liked Lucas (teste1):
      liking them back in the app creates a match.
    - Lucas (teste1) and Gabriel (teste5) are already matched, with a short
      chat (created only once).

  Passwords are read from tool/test_accounts.local.json (git-ignored, keys
  test1 … test10); they are never printed. Data is fictional.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File tool/seed_test_users.ps1
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$credFile = Join-Path $PSScriptRoot 'test_accounts.local.json'
$avatarDir = Join-Path $PSScriptRoot 'demo_avatars'

# Public Firebase client config (same values the app ships with).
$options = Get-Content (Join-Path $root 'lib\firebase_options.dart') -Raw
$androidBlock = [regex]::Match($options, 'android = FirebaseOptions\((?s:.*?)\);').Value
$apiKey = [regex]::Match($androidBlock, "apiKey: '([^']+)'").Groups[1].Value
$projectId = [regex]::Match($androidBlock, "projectId: '([^']+)'").Groups[1].Value
if (-not $apiKey -or -not $projectId) { throw 'Could not read firebase_options.dart' }

$authBase = 'https://identitytoolkit.googleapis.com/v1/accounts'
$docsBase = "projects/$projectId/databases/(default)/documents"
$apiBase = "https://firestore.googleapis.com/v1/$docsBase"
$commitUrl = "https://firestore.googleapis.com/v1/$docsBase`:commit"

# Fictional people. Skill ids must exist in Skills.all / firestore.rules.
$people = @(
  [ordered]@{ key = 'test1'; name = 'Lucas Ferreira'
    bio = 'Desenvolvedor e violonista nas horas vagas. Ensino programação e Python; quero destravar o inglês e aprender piano.'
    teach = @('programming', 'python', 'guitar'); learn = @('english', 'piano', 'photography', 'design')
    likes = @('test5') }
  [ordered]@{ key = 'test2'; name = 'Camila Ribeiro'
    bio = 'Professora de inglês e espanhol, escrevo para um blog de viagens. Quero aprender a programar e tocar violão.'
    teach = @('english', 'spanish', 'writing'); learn = @('programming', 'guitar', 'design', 'cooking')
    likes = @('test1') }
  [ordered]@{ key = 'test3'; name = 'Bruno Carvalho'
    bio = 'Fotógrafo de eventos e editor de vídeo. Quero aprender Python para automatizar meu fluxo e perder o medo de falar em público.'
    teach = @('photography', 'videoEditing', 'photoEditing'); learn = @('python', 'publicSpeaking', 'marketing', 'piano')
    likes = @('test1') }
  [ordered]@{ key = 'test4'; name = 'Ana Beatriz Lima'
    bio = 'Designer gráfica e ilustradora. Ensino design, desenho e marketing digital; quero aprender programação e piano.'
    teach = @('design', 'drawing', 'marketing'); learn = @('programming', 'piano', 'photography')
    likes = @() }
  [ordered]@{ key = 'test5'; name = 'Gabriel Nunes'
    bio = 'Pianista e professor de matemática. Cozinho muito bem! Quero aprender violão e programação.'
    teach = @('piano', 'math', 'cooking'); learn = @('guitar', 'programming', 'english', 'photography')
    likes = @('test1') }
  [ordered]@{ key = 'test6'; name = 'Daniel Moreira'
    bio = 'Palestrante e mentor de carreira. Ensino oratória, escrita e marketing; quero aprender programação e inglês.'
    teach = @('publicSpeaking', 'writing', 'marketing'); learn = @('programming', 'english', 'excel')
    likes = @() }
  [ordered]@{ key = 'test7'; name = 'Larissa Mendes'
    bio = 'Professora de inglês e física. Adoro escrever contos. Quero aprender Python e violão para tocar com os amigos.'
    teach = @('english', 'physics', 'writing'); learn = @('python', 'guitar', 'drawing')
    likes = @('test1') }
  [ordered]@{ key = 'test8'; name = 'Rafael Almeida'
    bio = 'Fotógrafo de natureza e artesão. Ensino fotografia, artesanato e Excel; quero aprender programação e violão.'
    teach = @('photography', 'crafts', 'excel'); learn = @('programming', 'guitar', 'english')
    likes = @('test1') }
  [ordered]@{ key = 'test9'; name = 'Juliana Martins'
    bio = 'Pianista e química. Cozinho pratos veganos! Quero aprender a programar em Python e melhorar o espanhol.'
    teach = @('piano', 'chemistry', 'cooking'); learn = @('python', 'programming', 'spanish')
    likes = @('test1') }
  [ordered]@{ key = 'test10'; name = 'Thiago Rocha'
    bio = 'Designer de produto e editor de vídeo. Ensino design e matemática; quero aprender violão, Python e oratória.'
    teach = @('design', 'videoEditing', 'math'); learn = @('guitar', 'python', 'publicSpeaking')
    likes = @('test1') }
  [ordered]@{ key = 'test11'; name = 'Mariana Souza'
    bio = 'Analista financeira que ama planilhas. Ensino Excel, marketing e escrita; quero aprender fotografia, espanhol e piano.'
    teach = @('excel', 'marketing', 'writing'); learn = @('photography', 'spanish', 'piano')
    likes = @('test12', 'test15') }
  [ordered]@{ key = 'test12'; name = 'Pedro Henrique Costa'
    bio = 'Músico e professor de física. Ensino violão e piano; quero dominar o Excel e melhorar meu inglês.'
    teach = @('guitar', 'piano', 'physics'); learn = @('excel', 'marketing', 'english')
    likes = @('test11', 'test13') }
  [ordered]@{ key = 'test13'; name = 'Beatriz Oliveira'
    bio = 'Química e confeiteira. Ensino química, culinária e desenho; quero aprender violão e editar vídeos da cozinha.'
    teach = @('chemistry', 'cooking', 'drawing'); learn = @('guitar', 'programming', 'videoEditing')
    likes = @('test12') }
  [ordered]@{ key = 'test14'; name = 'Felipe Santos'
    bio = 'Programador backend e fã de matemática. Ensino Python e lógica; quero aprender a desenhar e cozinhar melhor.'
    teach = @('programming', 'python', 'math'); learn = @('drawing', 'cooking', 'spanish')
    likes = @('test13', 'test17') }
  [ordered]@{ key = 'test15'; name = 'Isabela Fernandes'
    bio = 'Tradutora de espanhol e inglês, já morei em Madri. Ensino idiomas e oratória; quero aprender Excel e Python.'
    teach = @('spanish', 'english', 'publicSpeaking'); learn = @('excel', 'python', 'crafts')
    likes = @('test14') }
  [ordered]@{ key = 'test16'; name = 'Gustavo Pereira'
    bio = 'Videomaker de casamentos. Ensino edição de vídeo e fotografia; quero aprender inglês e escrever roteiros.'
    teach = @('videoEditing', 'photoEditing', 'photography'); learn = @('english', 'writing', 'guitar')
    likes = @('test20') }
  [ordered]@{ key = 'test17'; name = 'Letícia Araújo'
    bio = 'Ilustradora e artesã. Ensino design, desenho e artesanato; quero aprender Python e perder a timidez.'
    teach = @('design', 'drawing', 'crafts'); learn = @('python', 'publicSpeaking', 'physics')
    likes = @('test16') }
  [ordered]@{ key = 'test18'; name = 'Matheus Barbosa'
    bio = 'Gerente de marketing e palestrante. Ensino marketing, Excel e oratória; quero aprender design e piano.'
    teach = @('marketing', 'excel', 'publicSpeaking'); learn = @('design', 'piano', 'cooking')
    likes = @('test17', 'test19') }
  [ordered]@{ key = 'test19'; name = 'Sofia Cardoso'
    bio = 'Pianista e escritora. Ensino piano, escrita e inglês; quero aprender química, fotografia e programação.'
    teach = @('piano', 'writing', 'english'); learn = @('chemistry', 'photography', 'programming')
    likes = @('test12') }
  [ordered]@{ key = 'test20'; name = 'Vinícius Teixeira'
    bio = 'Cozinheiro e marceneiro de fim de semana. Ensino culinária, artesanato e violão; quero aprender a editar vídeos.'
    teach = @('cooking', 'crafts', 'guitar'); learn = @('videoEditing', 'math', 'english')
    likes = @('test18') }
)

# Existing matches with their chat, in order: sender key, text.
$chats = @(
  @{ pair = @('test1', 'test5'); messages = @(
      @('test5', 'Oi, Lucas! Vi que você ensina violão. Topa trocar por aulas de piano?'),
      @('test1', 'Topo sim, Gabriel! Sábado à tarde funciona pra você?'),
      @('test5', 'Perfeito, combinado! Começamos pelos acordes básicos?')) }
  @{ pair = @('test11', 'test12'); messages = @(
      @('test12', 'Oi, Mariana! Vi que você manda bem no Excel. Troco por aulas de violão?'),
      @('test11', 'Fechado, Pedro! Quinta à noite pode ser?'),
      @('test12', 'Pode sim! Eu levo o violão e você leva as planilhas.')) }
)

function Invoke-Json([string]$Uri, $Body, [string]$Token) {
  $headers = @{}
  if ($Token) { $headers.Authorization = "Bearer $Token" }
  $json = $Body | ConvertTo-Json -Depth 20 -Compress
  Invoke-RestMethod -Method Post -Uri $Uri -Headers $headers -ContentType 'application/json; charset=utf-8' `
    -Body ([Text.Encoding]::UTF8.GetBytes($json))
}

function Test-Doc([string]$Path, [string]$Token) {
  try {
    Invoke-RestMethod -Method Get -Uri "$apiBase/$Path" -Headers @{ Authorization = "Bearer $Token" } | Out-Null
    $true
  } catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) { return $false }
    throw
  }
}

function Get-Session([string]$Email, [string]$Password) {
  try {
    $r = Invoke-Json "$authBase`:signInWithPassword?key=$apiKey" @{ email = $Email; password = $Password; returnSecureToken = $true }
    $created = $false
  } catch {
    # New project accounts: create them (email enumeration protection
    # reports a missing account as INVALID_LOGIN_CREDENTIALS).
    $r = Invoke-Json "$authBase`:signUp?key=$apiKey" @{ email = $Email; password = $Password; returnSecureToken = $true }
    $created = $true
  }
  [pscustomobject]@{ uid = $r.localId; token = $r.idToken; created = $created }
}

function ArrayValue([string[]]$Items) {
  @{ arrayValue = @{ values = @($Items | ForEach-Object { @{ stringValue = $_ } }) } }
}

function New-Id {
  $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.ToCharArray()
  $bytes = New-Object byte[] 20
  [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

$creds = Get-Content $credFile -Raw | ConvertFrom-Json
$sessions = @{}

# 1. Accounts, consent and profiles.
foreach ($p in $people) {
  $c = $creds.($p.key)
  if (-not $c -or -not $c.email -or -not $c.password) {
    # Accounts whose password is not in the local file are left untouched.
    Write-Host "skipped $($p.name) (no '$($p.key)' in test_accounts.local.json)"
    continue
  }
  if ($p.name.Length -gt 40 -or $p.bio.Length -gt 160) { throw "Name or bio too long for $($p.key)" }
  $photo = [IO.File]::ReadAllBytes((Join-Path $avatarDir "teste$($p.key.Substring(4)).jpg"))
  # Same limit as ProfilePhoto.maxBytes: larger photos are not shown in the app.
  if ($photo.Length -gt 48KB) { throw "Avatar too large for $($p.key)" }

  $session = Get-Session $c.email $c.password
  $sessions[$p.key] = $session
  $uid = $session.uid

  $writes = @()
  $consentPath = "users/$uid/private/consent"
  if (-not (Test-Doc $consentPath $session.token)) {
    $writes += @{
      update = @{ name = "$docsBase/$consentPath"; fields = @{ termsVersion = @{ integerValue = '1' }; adult = @{ booleanValue = $true } } }
      updateTransforms = @(@{ fieldPath = 'acceptedAt'; setToServerValue = 'REQUEST_TIME' })
    }
  }
  $writes += @{
    update = @{
      name = "$docsBase/users/$uid"
      fields = @{
        name = @{ stringValue = $p.name }
        bio = @{ stringValue = $p.bio }
        teach = ArrayValue $p.teach
        learn = ArrayValue $p.learn
        photo = @{ bytesValue = [Convert]::ToBase64String($photo) }
      }
    }
    updateTransforms = @(@{ fieldPath = 'updatedAt'; setToServerValue = 'REQUEST_TIME' })
  }
  Invoke-Json $commitUrl @{ writes = $writes } $session.token | Out-Null
  $status = if ($session.created) { 'created' } else { 'updated' }
  Write-Host "$status $($p.name) <$($c.email)>"
}

# 2. Likes (after all profiles exist; the rules check the target exists).
foreach ($p in $people) {
  $me = $sessions[$p.key]
  if (-not $me) { continue }
  foreach ($t in $p.likes) {
    if (-not $sessions[$t]) { continue }
    $to = $sessions[$t].uid
    $like = @{
      writes = @(@{
        update = @{
          name = "$docsBase/likes/$($me.uid)_$to"
          fields = @{ from = @{ stringValue = $me.uid }; to = @{ stringValue = $to }; liked = @{ booleanValue = $true } }
        }
        updateTransforms = @(@{ fieldPath = 'createdAt'; setToServerValue = 'REQUEST_TIME' })
      })
    }
    Invoke-Json $commitUrl $like $me.token | Out-Null
    Write-Host "  $($p.name) liked $(($people | Where-Object key -eq $t).name)"
  }
}

# 3. Matches with a short chat (only when the match does not exist yet).
foreach ($chat in $chats) {
  $a = $sessions[$chat.pair[0]]; $b = $sessions[$chat.pair[1]]
  if (-not $a -or -not $b) { continue }
  $ids = @($a.uid, $b.uid)
  if ([string]::CompareOrdinal($ids[0], $ids[1]) -gt 0) { [array]::Reverse($ids) }
  $matchId = "$($ids[0])_$($ids[1])"
  if (Test-Doc "matches/$matchId" $a.token) { Write-Host "  match $($chat.pair -join ' + ') already exists"; continue }

  Invoke-Json $commitUrl @{ writes = @(@{
    update = @{
      name = "$docsBase/matches/$matchId"
      fields = @{
        userIds = ArrayValue $ids
        status = @{ stringValue = 'active' }
        lastMessage = @{ nullValue = $null }
        lastMessageId = @{ nullValue = $null }
      }
    }
    currentDocument = @{ exists = $false }
    updateTransforms = @(
      @{ fieldPath = 'createdAt'; setToServerValue = 'REQUEST_TIME' },
      @{ fieldPath = 'lastMessageAt'; setToServerValue = 'REQUEST_TIME' })
  }) } $a.token | Out-Null

  foreach ($m in $chat.messages) {
    $sender = $sessions[$m[0]]
    $messageId = New-Id
    Invoke-Json $commitUrl @{ writes = @(
      @{
        update = @{
          name = "$docsBase/matches/$matchId/messages/$messageId"
          fields = @{ senderId = @{ stringValue = $sender.uid }; text = @{ stringValue = $m[1] } }
        }
        currentDocument = @{ exists = $false }
        updateTransforms = @(@{ fieldPath = 'createdAt'; setToServerValue = 'REQUEST_TIME' })
      },
      @{
        update = @{
          name = "$docsBase/matches/$matchId"
          fields = @{ lastMessage = @{ stringValue = $m[1] }; lastMessageId = @{ stringValue = $messageId } }
        }
        updateMask = @{ fieldPaths = @('lastMessage', 'lastMessageId') }
        currentDocument = @{ exists = $true }
        updateTransforms = @(@{ fieldPath = 'lastMessageAt'; setToServerValue = 'REQUEST_TIME' })
      }) } $sender.token | Out-Null
    Start-Sleep -Milliseconds 300
  }
  Write-Host "  match $($chat.pair -join ' + ') created with $($chat.messages.Count) messages"
}
Write-Host 'Done. Credentials in tool/test_accounts.local.json (not printed).'
