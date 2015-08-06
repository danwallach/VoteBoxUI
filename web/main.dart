/**
 *
 */

import 'dart:html' hide XmlDocument;
import 'package:xml/xml.dart';
import 'package:chrome/chrome_app.dart' as chrome;

void main() {

  /* Load the Ballot from the XML file reference passed through localdata */
  Ballot ballot = loadBallot();
  
  /* If for some reason nothing is there, close the window or error or something */
  if (ballot == null) {
    chrome.app.window.current().close();
    return;
  }

  /* Set up listeners for the different buttons clicked */
  querySelector('#ID').onClick.listen(getID);
  querySelector('#button_begin').onClick.listen(gotoFirstInstructions);

  querySelector('#Back').onClick.listen(gotoInfo);
  querySelector('#Begin').onClick.listen((MouseEvent e) => display(e, 0, ballot));

  querySelector('#Previous').onClick.listen((MouseEvent e) => update(e, -1, ballot));
  querySelector('#Next').onClick.listen((MouseEvent e) => update(e, 1, ballot));

  querySelector('#Review').onClick.listen((MouseEvent e) => gotoReview(e, ballot));
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
 * Triggers on 'Begin' and renders the 'First Instructions' page
 */
void gotoFirstInstructions(MouseEvent event) {
  querySelector("#first_instructions").style.display="block"; //de-invisibles
  querySelector("#first_instructions").style.visibility="visible"; //displays instructions
  querySelector("#Back").style.visibility="visible"; //shows the back button that takes you to the election info page
  querySelector("#Begin").style.visibility="visible"; //shows the button that is pressed to start voting
  querySelector("#info").style.display="none"; //makes the instructions invisible
}

/**
 * Triggers on 'Back' and renders the 'Instructions' page
 */
void gotoInfo(MouseEvent event) {
  querySelector("#Begin").style.visibility="hidden"; //hides the begin and back buttons shown on the instructions page
  querySelector("#Back").style.visibility="hidden";
  querySelector("#first_instructions").style.display="none"; //makes the instructions invisible
  querySelector("#info").style.display="block"; //shows election information page or start

}

/**
 * Triggers on 'Return to Review' and re-renders the 'Review' page
 */
void gotoReview(MouseEvent event, Ballot e) {
  update(event, e.size()-e.getCurrentPage(), e);
}

void update(MouseEvent event, int delta, Ballot b) {

  /* Record information on currentPage */
  record(b);

  /* Display the new page */
  display(event, b.getCurrentPage()+delta, b);
}

/**
 * Records the current selection state of the current Race in the Ballot
 */
void record(Ballot b){
  /* Get the "votes" collection of elements from this page */
  Iterable<RadioButtonInputElement> selected;

  /* Get the currently selected candidate button(s) on the page */
  selected = (querySelector("#votes").getElementsByClassName("candidate")
                as List<RadioButtonInputElement>).where((RadioButtonInputElement el) => isSelected(el));

  /* There should never be more than one selected radio button... */
  if(selected.length == 1) {

    /* Mark the Option in this Race with the selection's name */
    b.getRace(b.getCurrentPage()).markSelection(selected.elementAt(0).getAttribute("name"));
  }
  else if (selected.length == 0){

    /* If nothing is selected, note it */
    b.getRace(b.getCurrentPage()).noSelection();
  }

}

/**
 * Returns the checked state of this radio button
 */
bool isSelected(RadioButtonInputElement e) {
  return e.checked;
}

/**
 * Renders the pageToDisplay in the Ballot as HTML in the UI
 */
void display(MouseEvent event, int pageToDisplay, Ballot b) {

  if (pageToDisplay < 0) pageToDisplay = 0;

  if(pageToDisplay >= b.size()) {
    displayReviewPage(b);
    b.updateCurrentPage(b.size());
  } else {
    displayRace(b.getRace(pageToDisplay));
    b.updateCurrentPage(pageToDisplay);
  }
}

/**
 * Renders this Race on the UI as HTML
 */
void displayRace(Race race) {

  /* Clear all other HTML */

  /* If nothing is selected show "skip" , otherwise "next" */

  /* Display the current race info */



}

/**
 * Renders the review page for the current state of this Ballot
 */
void displayReviewPage(Ballot e) {

  /* Clear all other HTML */

  /* Display only "Print Your Ballot" */

  /* Display review */

}

/**
 * Loads the ballot XML file from localdata and parses the XML as a String to be sent
 * to be converted into a Ballot object
 */
Ballot loadBallot() {

  String ballotXML;

  FileEntry entry;

  chrome.app.runtime.onLaunched.first.then((file) {
    entry = file as FileEntry;
  });

  entry.file().then((file) {
    FileReader reader = new FileReader();
    reader.onLoad.listen((e) => ballotXML = e.target.result);
    reader.readAsText(file);
  });

  if (ballotXML == null) {
    window.alert("The file was not loaded properly!");
    return null;
  }

  XmlDocument xmlDoc = parse(ballotXML);

  Ballot ballot = new Ballot();
  ballot.loadFromXML(xmlDoc);

  return ballot;
}

/**
 *
 */
class Ballot {

  List<Race> _races;
  int _currentPage=0;

  Ballot() {
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