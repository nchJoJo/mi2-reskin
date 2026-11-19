param(
    [string]$Game = '',
    [switch]$Dev
)
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
if (-not $Game) { throw "Couldn't find Melvor Idle 2 through Steam. Run it again with the game's folder: .\install.ps1 -Game 'D:\SteamLibrary\steamapps\common\Melvor Idle 2'" }
if (-not (Test-Path (Join-Path $Game 'Melvor2.exe'))) { throw "Melvor2.exe not found in $Game" }

$files = 'mi2_reskin.gd', 'mi2_reskin_core.gd', 'mi2_reskin_polish.gd', 'mi2_reskin_menu.gd', 'mi2_reskin.cfg', 'mi1_icons.cfg'
$cfg = Join-Path $Game 'override.cfg'
if ((Test-Path $cfg) -and -not (Select-String -Path $cfg -Pattern 'MI2Reskin' -Quiet)) {
    throw "$cfg already exists and belongs to another mod. Not overwriting it; merge its [autoload] section by hand."
}
$mod = Join-Path $Game 'mod'
New-Item -ItemType Directory -Force $mod | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'override.cfg') $cfg -Force
foreach ($f in $files) { Copy-Item (Join-Path $PSScriptRoot "mod\$f") $mod -Force }
$local = Join-Path $PSScriptRoot 'mod\mi2_reskin_local.cfg'
if (Test-Path $local) { Copy-Item $local $mod -Force } else { Remove-Item (Join-Path $mod 'mi2_reskin_local.cfg') -ErrorAction SilentlyContinue }
$fonts = Join-Path $mod 'fonts'
New-Item -ItemType Directory -Force $fonts | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'mod\fonts\*') $fonts -Force
if ($Dev) {
    $c = Join-Path $mod 'mi2_reskin.cfg'
    $text = (Get-Content $c -Raw) -replace '(?ms)(\[dev\].*?)enabled=false', '$1enabled=true'
    [IO.File]::WriteAllText($c, $text, (New-Object Text.UTF8Encoding $false))
}
Write-Output "Installed in $Game. Restart the game to apply it; F7 switches between the reskin and the original look."
