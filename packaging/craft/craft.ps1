# Wrapper cho CraftMaster - dung lai cau lenh cua .github/workflows/windows-build-and-test.yml
# Su dung: .\craft.ps1 <cac tham so craft>
$ErrorActionPreference = 'Continue'

$Python        = 'C:\Python312-x64\python.exe'
$MasterScript  = 'C:\CraftMaster\CraftMaster.py'
$ConfigFile    = 'C:\projects\datadrive\craftmaster.ini'
$Target        = 'windows-msvc2022_64-cl'
$Root          = 'C:\CraftRoot'

# vcvarsall.bat goi vswhere.exe khong theo duong dan tuyet doi. Neu no khong nam trong
# PATH, canh bao "not recognized" bi craft gop vao stdout va lam hong JSON moi truong
# (CraftSetupHelper._getOutput dung stderr=STDOUT).
$VsInstaller = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer"
if ((Test-Path "$VsInstaller\vswhere.exe") -and ($env:PATH -notlike "*$VsInstaller*")) {
    $env:PATH = "$VsInstaller;$env:PATH"
}

# GenerateIconsUtils.cmake can SVG_CONVERTER (inkscape) de sinh icon PNG tu SVG.
$Inkscape = 'C:\Program Files\Inkscape\bin'
if ((Test-Path "$Inkscape\inkscape.exe") -and ($env:PATH -notlike "*$Inkscape*")) {
    $env:PATH = "$env:PATH;$Inkscape"
}

$Override = Join-Path $PSScriptRoot 'lowmem-override.ini'

& $Python $MasterScript --config $ConfigFile --config-override $Override `
    --variables "Root=$Root" --target $Target -c @args
exit $LASTEXITCODE
