call cd ..
call pub get
call pub build
call xcopy /Y build\web\main.dart.js web\main.dart.js
call "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --profile-directory=Default --app-id=cmihjophmollkbaedddfdecihgbjdamd "C:\Users\seclab2\Desktop\election.xml"
cd nonSecuredWebServer
call dart %cd%\printerServer.dart
cd ..