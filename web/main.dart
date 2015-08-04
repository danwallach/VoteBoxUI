/**
 *
 */

import 'dart:html';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:chrome/chrome_app.dart' as chrome;

void main() {

  Election = loadElection();

  if (election == null) {
    return;
  }

  querySelector('#ID').onClick.listen(getID);
  querySelector('#button_begin').onClick.listen(gotoFirstInstructions);

  querySelector('#Back').onClick.listen(gotoInfo);
  querySelector('#Begin').onClick.listen(beginElection);

  querySelector('#Previous').onClick.listen(displayCurrent);
  querySelector('#Next').onClick.listen(displayCurrent);


}

void getID(MouseEvent event) {
  String ID = querySelector('#idText').text;

  // Right now this always gets an empty string for some reason
  /*if(ID==""){
        // this should actually be a popup or something
        querySelector('#ID').text = "You must enter correctly your 5-digit authentication number.";
    }
    else{*/

  querySelector("#IDArea").text = ID + " STAR-Vote";
  querySelector("#info").style.visibility="visible"; //shows election information page or start
  querySelector("#ID").style.display="none"; //hides the elements on the authentication page
  querySelector("#enterID").style.display="none";
  querySelector("#idText").style.display="none";
  //}

}

void gotoFirstInstructions(MouseEvent event) {
  querySelector("#first_instructions").style.display="block"; //de-invisibles
  querySelector("#first_instructions").style.visibility="visible"; //displays instructions
  querySelector("#Back").style.visibility="visible"; //shows the back button that takes you to the election info page
  querySelector("#Begin").style.visibility="visible"; //shows the button that is pressed to start voting
  querySelector("#info").style.display="none"; //makes the instructions invisible
}

void gotoInfo(MouseEvent event) {
  querySelector("#Begin").style.visibility="hidden"; //hides the bigin and back buttons shown on the instructions page
  querySelector("#Back").style.visibility="hidden";
  querySelector("#first_instructions").style.display="none"; //makes the instructions invisible
  querySelector("#info").style.display="block"; //shows election information page or start

}

void beginElection(MouseEvent event){

}

Map recordEvent(MouseEvent event) {

  Map e = new Map<String, String>();
  DateTime time = new DateTime.now();
  String type = (event.target as ButtonElement).id;
  String timeStamp = time.toIso8601String();

  e.putIfAbsent("type", (type as dynamic));
  e.putIfAbsent("time", (timeStamp as dynamic));

  if(getCurrentRaceIndex()<27){
    e.putIfAbsent("page", getRaces().get(getCurrentRaceIndex()).number);
  }
  else if(getCurrentRaceIndex()>26){
    e.putIfAbsent("page", ("" as dynamic));
  }

  return e;
}

Election loadElection(String path) {

  //checkSupport()

  var electionFile = new File(path);

  if(!electionFile.existsSync()) return null;

  var electionXML = parse(await());
  if (electionXML==null){
    window.alert ("Your browser does not support XMLHTTP!");
    return null;
  }

  Election election = new Election();

  /* When state = 4 the file has been received */
  if (currentState ==  4) {
    xmlhttp
    election = buildRaces(xmlhttp.responseXML);
  }

  String fileName="election.xml";
  xmlhttp.onreadystatechange=resultOfChange;
  xmlhttp.open("GET",fileName,true);
  xmlhttp.send(null);
  return resultOfChange;
}

//checks if browser supports XML or ActiveObject
GetXmlHttpObject() {
  /*if (window.XMLHttpRequest()){
        return new XMLHttpRequest();
    }
    if (window.ActiveXObject()){
        return new ActiveXObject("Microsoft.XMLHTTP");
    }*/
}

stateChanged(xmlhttp){
  var state=xmlhttp.readyState;

  /* Puts the state in the status field just for testing purposes */
  querySelector('#Debug').text=state;

  return state;
}

buildRaces(xml){
  int numberOfRaces = xml.getElementsByTagName("race").length;
  var races = [];

  for (int j = 0; j < numberOfRaces; j++){
    races[j] = {};
    var currentRace = xml.getElementsByTagName("race")[j];
    races[j].title = currentRace.getElementsByTagName("title")[0].firstChild.nodeValue;
    races[j].number = currentRace.getElementsByTagName("number")[0].firstChild.nodeValue;
    races[j].cand = currentRace.getElementsByTagName("candidate");

    races[j].candidates = [];
    for (var i=0;i<races[j].cand.length;i++) {
      races[j].candidates[i] = {};
      races[j].candidates[i].index = i;
      races[j].candidates[i].voted = false;
      races[j].candidates[i].name = races[j].cand[i].getElementsByTagName("name")[0].firstChild.nodeValue;
      races[j].candidates[i].party = races[j].cand[i].getElementsByTagName("party")[0].firstChild.nodeValue;
    }
  }

  int numberOfProps = xml.getElementsByTagName("proposition").length;
  var props = [];
  //alert("number of props"+numberOfProps)
  for (int p = 0; p < numberOfProps; p++){
    props[p] = {};
    props[p].log = [];
    var currentProp = xml.getElementsByTagName("proposition")[p];
    props[p].title = currentProp.getElementsByTagName("title")[0].firstChild.nodeValue;
    props[p].text = currentProp.getElementsByTagName("propositionText")[0].firstChild.nodeValue;
    props[p].number = currentProp.getElementsByTagName("number")[0].firstChild.nodeValue;
    props[p].cand = currentProp.getElementsByTagName("response");

    props[p].candidates = [];
    for (var l=0; l<props[p].cand.length;l++) {
      props[p].candidates[l] = {};
      props[p].candidates[l].index = l;
      props[p].candidates[l].voted = false;
      if(l == 0){
        props[p].candidates[l].name= "Yes";
        props[p].candidates[l].party = " ";
      }
      else{
        props[p].candidates[l].name = "No";
        props[p].candidates[l].party = " ";
      }
      //props[p].candidates[l].name = props[p].cand[l].getElementsByTagName("response")[0].firstChild.nodeValue
    }
  }

  return races.addAll(props);
  //alert("Races legnth: "+races1.length);
  //alert("Races legnth: "+races.length);
  //alert("Props Length: "+props.length);
}

class Election {

}