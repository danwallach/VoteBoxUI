call cd ..
call pub get
call pub build
call xcopy /Y build\web\main.dart.js web\main.dart.js
<<<<<<< HEAD
call "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --profile-directory=Default --app-id=jinjkkheinoeggackbhoiggmoegackko "%USERPROFILE%\Desktop\election.xml"
=======
call cd nonSecuredWebServer
call dart "%cd%\localServer.dart"
call cd ..\launchScripts
>>>>>>> origin/BAM_branch2
