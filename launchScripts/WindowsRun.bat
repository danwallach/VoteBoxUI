call cd ..
call "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --profile-directory=Default --app-id=cmihjophmollkbaedddfdecihgbjdamd "C:%HOMEPATH%\Desktop\election.xml"
call cd nonSecuredWebServer
call dart %cd%\printerServer.dart
call cd ..