$ErrorActionPreference = 'Stop'
$env:Path = 'C:\src\flutter\bin;' + $env:Path
if (!(Test-Path 'C:\src\flutter\bin\flutter.bat')) { throw '未找到 Flutter SDK，请检查安装路径。' }
Set-Location (Join-Path $PSScriptRoot '..\client')
flutter run -d chrome
