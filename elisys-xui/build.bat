cd elisys-xui
dart2js -O2 -o libxui.dart.js web\libxui.dart
copy libxui.js dist\libxui.js
copy web\* dist\
copy web\app\* dist\app\

del dist\*.dart