# Compila la app de escritorio para Windows y la empaqueta en
# web/downloads/aeroparts-windows-x64.zip (la descarga que ofrece la web).
#
#     powershell -ExecutionPolicy Bypass -File tool\package_windows.ps1
#
# Debe ejecutarse EN WINDOWS: Flutter no compila para Windows desde Linux.
# Requiere Visual Studio 2022 con la carga "Desarrollo para el escritorio con
# C++". Sin una maquina Windows, usa el workflow
# .github/workflows/build-windows.yml, que hace lo mismo en GitHub Actions.
$ErrorActionPreference = 'Stop'

$Root  = Resolve-Path (Join-Path $PSScriptRoot '..')
$Stage = Join-Path $Root 'build\windows-package\AeroParts'
$Out   = Join-Path $Root 'web\downloads\aeroparts-windows-x64.zip'

Set-Location $Root
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw 'flutter build windows fallo' }

if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
New-Item -ItemType Directory -Path $Stage | Out-Null
Copy-Item 'build\windows\x64\runner\Release\*' $Stage -Recurse

# El ejecutable se llama como el proyecto; se renombra a algo legible.
Rename-Item (Join-Path $Stage 'aviation_inventory.exe') 'AeroParts.exe'
Copy-Item 'windows\runner\resources\app_icon.ico' (Join-Path $Stage 'AeroParts.ico')

# Instalador para el usuario actual (sin permisos de administrador): copia la
# app a %LOCALAPPDATA% y crea accesos directos en el Escritorio y en Inicio.
@'
$ErrorActionPreference = 'Stop'
$Src  = $PSScriptRoot
$Dest = Join-Path $env:LOCALAPPDATA 'AeroParts'
if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
Copy-Item $Src $Dest -Recurse
$Shell = New-Object -ComObject WScript.Shell
foreach ($Dir in @([Environment]::GetFolderPath('Desktop'),
                   (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'))) {
  $Link = $Shell.CreateShortcut((Join-Path $Dir 'AeroParts.lnk'))
  $Link.TargetPath = Join-Path $Dest 'AeroParts.exe'
  $Link.WorkingDirectory = $Dest
  $Link.IconLocation = Join-Path $Dest 'AeroParts.ico'
  $Link.Description = 'Inventario de repuestos aeronauticos'
  $Link.Save()
}
Write-Host 'AeroParts instalado. Abrelo desde el Escritorio o el menu Inicio.'
'@ | Set-Content (Join-Path $Stage 'instalar.ps1') -Encoding UTF8

@'
@echo off
rem Doble clic para instalar AeroParts (sin permisos de administrador).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar.ps1"
pause
'@ | Set-Content (Join-Path $Stage 'Instalar AeroParts.bat') -Encoding ASCII

@'
AeroParts - Inventario de repuestos aeronauticos
================================================

Opcion 1: doble clic en "Instalar AeroParts.bat". Crea accesos directos en el
Escritorio y en el menu Inicio.

Opcion 2: abrir AeroParts.exe directamente desde esta carpeta (no instala nada).

No muevas AeroParts.exe fuera de esta carpeta: necesita la carpeta "data" y
las DLL que lo acompanan.
'@ | Set-Content (Join-Path $Stage 'LEEME.txt') -Encoding UTF8

New-Item -ItemType Directory -Path (Split-Path $Out) -Force | Out-Null
if (Test-Path $Out) { Remove-Item $Out -Force }
Compress-Archive -Path $Stage -DestinationPath $Out
$SizeMb = [math]::Round((Get-Item $Out).Length / 1MB, 1)
Write-Host "Paquete listo: web\downloads\aeroparts-windows-x64.zip ($SizeMb MB)"
