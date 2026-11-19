param([string]$Version = '')
if (-not $Version) {
    $m = Select-String -Path (Join-Path $PSScriptRoot 'mod\mi2_reskin_core.gd') -Pattern '^const VERSION := "(.+)"' | Select-Object -First 1
    if (-not $m) { throw 'No VERSION in mod\mi2_reskin_core.gd' }
    $Version = $m.Matches[0].Groups[1].Value
}
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$name = "MI2-Reskin-$Version"
$stage = Join-Path $root "dist\$name"
$zip = Join-Path $root "dist\$name.zip"

$items = 'README.md', 'LICENSE', 'install.ps1', 'uninstall.ps1', 'Install.cmd', 'Uninstall.cmd', 'override.cfg',
         'mod\mi2_reskin.gd', 'mod\mi2_reskin_core.gd', 'mod\mi2_reskin_polish.gd', 'mod\mi2_reskin_menu.gd',
         'mod\mi2_reskin.cfg', 'mod\mi1_icons.cfg'
$items += Get-ChildItem (Join-Path $root 'mod\fonts') -File | ForEach-Object { "mod\fonts\$($_.Name)" }

if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
if (Test-Path $zip) { Remove-Item $zip -Force }
foreach ($i in $items) {
    $to = Join-Path $stage $i
    New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
    Copy-Item (Join-Path $root $i) $to
}

$problems = @()
$all = Get-ChildItem $stage -Recurse -File
$art = $all | Where-Object { $_.Extension -match '^\.(png|jpe?g|webp|svg|gif|bmp|tga|dds|ktx|ctex|pck|ogg|wav|mp3)$' }
if ($art) { $problems += "pictures or game data: $($art.Name -join ', ')" }
$cfgText = Get-Content (Join-Path $stage 'mod\mi2_reskin.cfg') -Raw
if ($cfgText -notmatch '(?ms)\[dev\][^\[]*?^enabled=false') { $problems += 'mod\mi2_reskin.cfg: [dev] enabled must be false' }
foreach ($f in $all | Where-Object Extension -eq '.ttf') {
    $family = $f.BaseName -replace '-[^-]+$', ''
    if (-not (Test-Path (Join-Path $f.DirectoryName "OFL-$family.txt"))) { $problems += "$($f.Name) has no OFL-$family.txt" }
}
$mine = [regex]::Escape($env:USERPROFILE)
$text = $all | Where-Object Extension -in '.md', '.ps1', '.cmd', '.cfg', '.gd' | Where-Object { (Get-Content $_.FullName -Raw) -match $mine }
if ($text) { $problems += "paths from this computer in: $($text.Name -join ', ')" }
if ($problems) { throw "Not packaged:`n - $($problems -join "`n - ")" }

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::Open($zip, 'Create')
try {
    foreach ($f in Get-ChildItem $stage -Recurse -File) {
        $entry = "$name/" + $f.FullName.Substring($stage.Length + 1).Replace([char]92, [char]47)
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entry, 'Optimal') | Out-Null
    }
} finally { $archive.Dispose() }
Remove-Item $stage -Recurse -Force
$kb = [math]::Round((Get-Item $zip).Length / 1KB)
Write-Output "Built $zip ($kb KB, $($items.Count) files)."
