call cd ..
call pub build
call xcopy /Y build\web\main.dart.js web\main.dart.js
<<<<<<< HEAD
call cd nonSecuredWebServer
call dart "%cd%\localServer.dart"
call cd ..\launchScripts
=======
call "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --profile-directory=Default --app-id=jinjkkheinoeggackbhoiggmoegackko "%USERPROFILE%\Desktop\election.xml"
>>>>>>> parent of ec90322... Merge remote-tracking branch 'origin/BAM_branch2'
