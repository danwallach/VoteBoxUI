#!/bin/bash 

#Replace everything after cd ~/ with the path to the VoteBoxUI directory
cd ~/CompSci/DanWallachLab/VoteBoxUI/
#(You'll need to do the same thing on the last line too, for the xml file)


#Handles dependancies
pub get

#Compiles the main.dart into the main.dart.js file that we need
pub build

#Howeverm the file is in the wrong place, so we copy it into where it needs to be
cp build/web/main.dart.js web/main.dart.js

#You may need to change the app-id; You can find it in the extensions tab of chrome
open -a /Applications/Google\ Chrome.app --args -profile-directory=Default --app-id=ddmglfacohaphcghfbilkomhbpnfoghe ~/CompSci/DanWallachLab/VoteBoxUI/web/election.xml
#Also, make sure both locations (for the chrome app AND the xml file) are correct!

