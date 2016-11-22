call cd ..
call pub get
call pub build
call xcopy /Y build\web\main.dart.js web\main.dart.js
call cd nonSecuredWebServer
call dart "%cd%\localServer.dart"
call cd ..\launchScripts