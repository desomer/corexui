cd elisys-xui
rem dart2js -O2 -o libxui.js web\libxui.dart
rem copy c:\xui\assets\app C:\src_dart\elisys-xui\web\app
copy libxui.js dist\libxui.js
copy web\* dist\