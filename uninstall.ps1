param([string]$Game = '')
$ErrorActionPreference = 'Stop'

function Find-Game {
    $steam = @()
    foreach ($key in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
        $p = Get-ItemProperty $key -ErrorAction SilentlyContinue
        if ($p.SteamPath) { $steam += $p.SteamPath }
        if ($p.InstallPath) { $steam += $p.InstallPath }
    }
    $steam += 'C:\Program Files (x86)\Steam', 'C:\Program Files\Steam'
    $libraries = @()
    foreach ($s in $steam) {
        $libraries += $s
        $vdf = Join-Path $s 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) { $libraries += $m.Groups[1].Value -replace '\\\\', '\' }
        }
    }
    foreach ($lib in $libraries | Select-Object -Unique) {
        $dir = 'Melvor Idle 2'
        $acf = Join-Path $lib 'steamapps\appmanifest_3218350.acf'
        if (Test-Path $acf) {
            $m = [regex]::Match((Get-Content $acf -Raw), '"installdir"\s+"([^"]+)"')
            if ($m.Success) { $dir = $m.Groups[1].Value }
        }
        $g = Join-Path $lib "steamapps\common\$dir"
        if (Test-Path (Join-Path $g 'Melvor2.exe')) { return (Resolve-Path $g).Path }
    }
    return $null
}

if (-not $Game) { $Game = Find-Game }
if (-not $Game) { throw "Couldn't find Melvor Idle 2 through Steam. Run it again with the game's folder: .\uninstall.ps1 -Game 'D:\SteamLibrary\steamapps\common\Melvor Idle 2'" }
if (-not (Test-Path (Join-Path $Game 'Melvor2.exe'))) { throw "Melvor2.exe not found in $Game" }

$files = 'mi2_reskin.gd', 'mi2_reskin_core.gd', 'mi2_reskin_polish.gd', 'mi2_reskin_menu.gd', 'mi2_reskin.cfg', 'mi1_icons.cfg', 'mi2_reskin_local.cfg'
$cfg = Join-Path $Game 'override.cfg'
if ((Test-Path $cfg) -and (Select-String -Path $cfg -Pattern 'MI2Reskin' -Quiet)) { Remove-Item $cfg }
$mod = Join-Path $Game 'mod'
foreach ($f in $files) { Remove-Item (Join-Path $mod $f) -ErrorAction SilentlyContinue }
$fonts = Join-Path $mod 'fonts'
$names = @(Get-ChildItem (Join-Path $PSScriptRoot 'mod\fonts') -File | ForEach-Object Name) + 'Cinzel.ttf', 'OFL.txt'
foreach ($f in $names) { Remove-Item (Join-Path $fonts $f) -ErrorAction SilentlyContinue }
if ((Test-Path $fonts) -and -not (Get-ChildItem $fonts)) { Remove-Item $fonts }
if ((Test-Path $mod) -and -not (Get-ChildItem $mod)) { Remove-Item $mod }
Write-Output "Removed from $Game. Restart the game to get the original look back."
