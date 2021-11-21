cd elisys-xui

rmdir /s /q dist\

mkdir dist\
copy libxui.dart.js dist\libxui.dart.js
copy web\* dist\

mkdir dist\app\
copy web\app\* dist\app\

mkdir dist\app\template\
mkdir dist\app\vue\

copy web\app\template\* dist\app\template\
copy web\app\vue\* dist\app\vue\

del dist\*.dart
del dist\app\*.md