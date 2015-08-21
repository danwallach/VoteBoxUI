# VoteBoxUI
Chrome App for the user interface of a voting session of the STAR-Vote system

To use in windows:

`"path\to\chrome.exe" --profile-directory=Default --app-id=jinjkkheinoeggackbhoiggmoegackko "path\to\electionfile.xml"`





To use in MacOSX:


First, install pub.

Second,  make sure that Chrome is NOT running (you must QUIT out of it, either by 
right clicking or command-q; if it's still running, even if you closed every tab
with command-w, it won't open the app correctly until you quit chrome first)

Third, run the following command in the terminal, after cd'ing into the VoteBoxUI directory

pub get
pub build
cp build/web/main.dart.js web/main.dart.js

Fourth, to launch the app, replace whatever is in quotes with the necessary info:
open -a "/Path/To/Your/Google\ Chrome.app" -args -profile-directory=Default --app-id="WhateverYourAppIDIs" ~/Path/To/The/Elections/File/elections.xml







(If this is annoying to type over and over, you can automate it fairly easily:

Copy the shell script in the launchScripts directory, and replace the file
path to Chrome, the file path to this folder (there are two of them you need
to replace!) and the appid with whatever they are for your computer.  


Lastly, just run the new shell script that you created by doing this from inside 
this directory.

For me, this means just typing the following into the terminal:
sh launchScripts/macOSXClayton.sh

Also, unmatched left parenthesis create unresolved tension. Can't have that :)
