cd elisys-xui
rem dart2js -O2 -o libxui.dart.js web\libxui.dart

copy libxui.dart.js dist\libxui.dart.js
copy web\* dist\
copy web\app\* dist\app\

del dist\*.dart