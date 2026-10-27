<#
  release-windows.ps1 - kiosk ilovasini Setup.exe ga yig'ish (ADR-037).
  Kit: C:\flutter_projects\Qabulxona\_kiosk_update_kit (5 repoda bir xil).

  Oddiy reliz:
    powershell -ExecutionPolicy Bypass -File scripts\release-windows.ps1 -Changelog "- ..."
  Natija: dist\<MyAppName>_Setup_vX.Y.Z.exe + SHA-256 + dist\version.json (namuna).
  Serverga FAQAT .exe yuklanadi (admin sahifa "Kiosk yangilanishlari") -
  version.json ni server o'zi yozadi.

  Lokal sinov build'i (prod'ga YUKLANMAYDI):
    ... -Test -TestBase http://127.0.0.1:8765 -OutDir dist-test
  -> UPDATE_TEST=true, version.json/setup_url localhost'dan, tez taymerlar.
#>
param(
  [string]$Changelog = "",
  [string]$MinVersion = "",
  [switch]$SkipBuild,
  [switch]$Test,
  [string]$TestBase = "http://127.0.0.1:8765",
  [string]$OutDir = "dist",
  [string[]]$ExtraBuildArgs = @()
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# --- loyiha qiymatlari: pubspec + setup.iss ---
$pub = Get-Content pubspec.yaml -Raw
$m = [regex]::Match($pub, '(?m)^version:\s*(\d+\.\d+\.\d+)')
if (-not $m.Success) { throw "pubspec.yaml da 'version: X.Y.Z' topilmadi" }
$v = $m.Groups[1].Value
$appKey = [regex]::Match($pub, '(?m)^name:\s*(\S+)').Groups[1].Value
$iss = Get-Content installer\setup.iss -Raw
$appName = [regex]::Match($iss, '#define MyAppName "([^"]+)"').Groups[1].Value
if (-not $appName) { throw "installer\setup.iss da MyAppName yo'q" }
$outAbs = Join-Path $root $OutDir
New-Item -ItemType Directory -Force $outAbs | Out-Null
Write-Host "== $appKey v$v ($appName)$(if ($Test) { ' [SINOV]' })" -ForegroundColor Cyan

# --- 1. Flutter build ---
if (-not $SkipBuild) {
  $fArgs = @('build', 'windows', '--release', '--obfuscate', "--split-debug-info=$OutDir\symbols\$v")
  if ($Test) {
    $fArgs += @(
      '--dart-define=UPDATE_TEST=true',
      "--dart-define=UPDATE_URL=$TestBase/$appKey/version.json",
      '--dart-define=UPDATE_FIRST_DELAY_SEC=15',
      '--dart-define=UPDATE_INTERVAL_MIN=1',
      '--dart-define=UPDATE_IDLE_SEC=20',
      '--dart-define=UPDATE_WARNING_SEC=8'
    )
  }
  $fArgs += $ExtraBuildArgs
  & flutter @fArgs
  if ($LASTEXITCODE -ne 0) { throw "flutter build windows xato ($LASTEXITCODE)" }
}
$rel = Join-Path $root 'build\windows\x64\runner\Release'
if (-not (Test-Path $rel)) { throw "$rel yo'q - avval build qiling" }

# --- 2. VC++ runtime (toza Windows'da VCRUNTIME140_1.dll xatosi bo'lmasin) ---
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
  Copy-Item "$env:WINDIR\System32\$dll" $rel -Force
}

# --- 3. KioskLauncher.exe (Shell Launcher qobig'i) ---
$csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$lDir = Join-Path $root 'build\launcher'
New-Item -ItemType Directory -Force $lDir | Out-Null
& $csc /nologo /target:winexe /optimize+ "/out:$lDir\KioskLauncher.exe" `
  "/win32icon:$root\windows\runner\resources\app_icon.ico" "$root\installer\launcher\KioskLauncher.cs"
if ($LASTEXITCODE -ne 0) { throw "KioskLauncher.cs kompilyatsiya xatosi" }

# --- 4. Inno Setup ---
$iscc = @("${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe", "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe") |
  Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw "ISCC.exe topilmadi: winget install --id JRSoftware.InnoSetup -e" }
& $iscc /Q "/DMyAppVersion=$v" "/DMyOutputDir=$outAbs" installer\setup.iss
if ($LASTEXITCODE -ne 0) { throw "ISCC xato ($LASTEXITCODE)" }

$exeName = "${appName}_Setup_v$v.exe"
$exe = Join-Path $outAbs $exeName
$hash = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLower()
$size = [math]::Round((Get-Item $exe).Length / 1MB, 1)

# --- 5. version.json (namuna / lokal sinov) ---
$base = if ($Test) { "$TestBase/$appKey" } else { "https://qabulxona.gennis.uz/downloads/kiosk/$appKey" }
$json = [ordered]@{
  app         = $appKey
  version     = $v
  min_version = $(if ($MinVersion) { $MinVersion } else { "0.0.0" })
  setup_url   = "$base/$exeName"
  sha256      = $hash
  changelog   = $Changelog
} | ConvertTo-Json
# Set-Content -Encoding utf8 EMAS - PowerShell 5.1 BOM qo'shadi va jsonDecode yiqiladi
[IO.File]::WriteAllText((Join-Path $outAbs 'version.json'), $json)

Write-Host ""
Write-Host "Tayyor: $exe ($size MB)" -ForegroundColor Green
Write-Host "sha256: $hash"
if (-not $Test) {
  Write-Host "Serverga: admin panel -> Sozlamalar -> Kiosk yangilanishlari -> $appKey -> faqat .exe yuklang." -ForegroundColor Yellow
  Write-Host "Symbols: $OutDir\symbols\$v (saqlang, serverga emas)"
}
