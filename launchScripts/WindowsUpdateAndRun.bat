call cd ..
call pub build
call xcopy /Y build\web\main.dart.js web\main.dart.js
call "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --profile-directory=Default --app-id=jinjkkheinoeggackbhoiggmoegackko "%USERPROFILE%\Desktop\election.xml"