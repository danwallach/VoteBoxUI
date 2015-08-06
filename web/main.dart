/**
 *
 */

import 'dart:html' hide XmlDocument;
import 'package:xml/xml.dart';
import 'package:chrome/chrome_app.dart' as chrome;

void main() {

  /* Load the election from the XML file reference passed through localdata */
  Election election = loadElection();
  
  /* If for some reason nothing is there, close the window or error or something */
  if (election == null) {
    chrome.app.window.current().close();
    return;
  }

  /* Set up listeners for the different buttons clicked */
  querySelector('#ID').onClick.listen(getID);
  querySelector('#button_begin').onClick.listen(gotoFirstInstructions);

  querySelector('#Back').onClick.listen(gotoInfo);
  querySelector('#Begin').onClick.listen((MouseEvent e) => display(e, 0, election));

  querySelector('#Previous').onClick.listen((MouseEvent e) => update(e, -1, election));
  querySelector('#Next').onClick.listen((MouseEvent e) => update(e, 1, election));

  querySelector('#Review').onClick.listen((MouseEvent e) => gotoReview(e, election));
}

/**
 * On click from 'Submit' for ID, this will pull the ID and right now just moves on.
 */
void getID(MouseEvent event) {
  String ID = querySelector('#idText').text;

  if(ID==""){
        // this should actually be a popup or something
        window.alert("You must enter correctly your 5-digit authentication number.");
    }
    else{

    /* TODO: Verify this ID by sending it back to Supervisor */
    querySelector("#IDArea").text = ID + " STAR-Vote";
    querySelector("#info").style.visibility="visible"; //shows election information page or start
    querySelector("#ID").style.display="none"; //hides the elements on the authentication page
    querySelector("#enterID").style.display="none";
    querySelector("#idText").style.display="none";
  }

}

/**
 *
 */
void gotoFirstInstructions(MouseEvent event) {
  querySelector("#first_instructions").style.display="block"; //de-invisibles
  querySelector("#first_instructions").style.visibility="visible"; //displays instructions
  querySelector("#Back").style.visibility="visible"; //shows the back button that takes you to the election info page
  querySelector("#Begin").style.visibility="visible"; //shows the button that is pressed to start voting
  querySelector("#info").style.display="none"; //makes the instructions invisible
}

/**
 *
 */
void gotoInfo(MouseEvent event) {
  querySelector("#Begin").style.visibility="hidden"; //hides the begin and back buttons shown on the instructions page
  querySelector("#Back").style.visibility="hidden";
  querySelector("#first_instructions").style.display="none"; //makes the instructions invisible
  querySelector("#info").style.display="block"; //shows election information page or start

}

/**
 *
 */
void gotoReview(MouseEvent event, Election e) {
  update(event, e.size()-e.getCurrentPage(), e);
}

void update(MouseEvent event, int delta, Election e) {

  /* Record information on currentPage */
  record(e);

  /* Display the new page */
  display(event, e.getCurrentPage()+delta, e);
}

/**
 *
 */
void record(Election e){
  /* Get the "votes" collection of elements from this page */
  RadioButtonInputElement selected;

  try {
    selected = (querySelector("#votes").getElementsByClassName("candidate")
    as List<RadioButtonInputElement>).singleWhere((RadioButtonInputElement el) => isSelected(el));

    e.getRace(e.getCurrentPage()).markSelection(selected.getAttribute("name"));

  } catch (exception) {
    e.getRace(e.getCurrentPage()).noSelection();
  }

}

bool isSelected(RadioButtonInputElement e) {
  return e.checked;
}

/**
 *
 */
void display(MouseEvent event, int pageToDisplay, Election e) {

  if (pageToDisplay < 0) pageToDisplay = 0;

  if(pageToDisplay >= e.size()) {
    displayReviewPage(e);
    e.updateCurrentPage(e.size());
  } else {
    displayRace(e.getRace(pageToDisplay));
    e.updateCurrentPage(pageToDisplay);
  }
}

/**
 *
 */
void displayRace(Race race) {

  /* Clear all other HTML */

  /* If nothing is selected show "skip" , otherwise "next" */

  /* Display the current race info */



}

/**
 *
 */
void displayReviewPage(Election e) {

  /* Clear all other HTML */

  /* Display only "Print Your Ballot" */

  /* Display review */

}

/**
 *
 */
Election loadElection() {

  String electionXML;

  FileEntry entry;

  chrome.app.runtime.onLaunched.first.then((file) {
    entry = file as FileEntry;
  });

  entry.file().then((file) {
    FileReader reader = new FileReader();
    reader.onLoad.listen((e) => electionXML = e.target.result);
    reader.readAsText(file);
  });

  if (electionXML == null) {
    window.alert("The file was not loaded properly!");
    return null;
  }

  XmlDocument xmlDoc = parse(electionXML);

  Election election = new Election();
  election.loadFromXML(xmlDoc);

  return election;
}

/**
 *
 */
class Election {

  List<Race> _races;
  int _currentPage=0;

  Election() {
    _races = new List<Race>();
  }

  int size() {
    return _races.length;
  }

  Race getRace(int index) {
    return _races.elementAt(index);
  }

  int getCurrentPage() {
    return _currentPage;
  }

  void updateCurrentPage(int newPage) {
    _currentPage = newPage;
  }

  void loadFromXML(XmlDocument xml) {

    List<XmlElement> raceList = xml.findElements("race");

    for (XmlElement race in raceList) {

      String title = race.getAttribute("title");
      List<XmlElement> XMLcandidates = race.findElements("candidate");
      List<Option> candidates = new List<Option>();

      for (XmlElement element in XMLcandidates) {
        candidates.add(new Option(element.getAttribute("name"), groupAssociation: element.getAttribute("party")));
      }

      Race currentRace = new Race(title, candidates);
      _races.add(currentRace);

    }

    List<XmlElement> propList = xml.findElements("proposition");

    for (XmlElement prop in propList) {

      String title = prop.getAttribute("title");
      String text = prop.getAttribute("propositionText");
      List<XmlElement> XMLresponses = prop.findElements("response");
      List<Option> responses = new List<Option>();

      for (XmlElement element in XMLresponses) {
        responses.add(new Option(XMLresponses.indexOf(element) == 0 ? "Yes" : "No"));
      }

      Race currentRace = new Race(title, responses, text: text);
      _races.add(currentRace);

    }

  }

}

/**
 *
 */
class Race {

  String _title;
  List<Option> _options;
  String text;
  bool _voted=false;

  Race(this._title, this._options, {this.text});

  bool hasVoted() {
    return _voted;
  }

  void markSelection(String identifier) {
    _voted = true;

    for(Option o in _options) {
      o.unmark();

      if (o._identifier == identifier)
        o.mark();
    }
  }

  void noSelection(){
    _voted = false;

    for(Option o in _options) {
      o.unmark();
    }

  }

}

/**
 *
 */
class Option {
  String _identifier;
  String groupAssociation;
  bool _voted=false;

  Option(this._identifier, {this.groupAssociation});

  bool wasSelected(){
    return _voted;
  }

  void mark() {
    _voted = true;
  }

  void unmark(){
    _voted = false;
  }

}