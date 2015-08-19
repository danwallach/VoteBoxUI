/**
 * The main guts of the Voting Session UI (current project name 'VoteBoxUI')
 */

import 'dart:html' hide XmlDocument;
import 'package:xml/xml.dart';
import 'package:chrome/chrome_app.dart' as chrome;
import 'dart:async';

main() async {

  document.onKeyDown.listen(blockKeys);
  document.onKeyUp.listen((e) { if (e.keyCode == 27 /* ESC */) { e.preventDefault(); }});

  Ballot ballot;

  /* Load the Ballot from the XML file reference passed through localdata */
  print("Loading ballot...");
  ballot = await loadBallot();
  print("Ballot has ${ballot.size()} races and propositions detected.");
  print("$ballot");

  /* Set up listeners for the different buttons clicked */
  querySelector('#ID').onClick.listen(getID);
  /* TODO: perhaps check for 'enter key' event on textinputelement */

  querySelector('#okay').onClick.listen(close);

  querySelector('#button_begin').onClick.listen(gotoFirstInstructions);

  querySelector('#Back').onClick.listen(gotoInfo);
  querySelector('#Begin').onClick.listen((MouseEvent e) => display(e, 0, ballot));

  querySelector('#Previous').onClick.listen((MouseEvent e) => update(e, -1, ballot));
  querySelector('#Next').onClick.listen((MouseEvent e) => update(e, 1, ballot));

  querySelector('#Review').onClick.listen((MouseEvent e) => gotoReview(e, ballot));
}

/**
 * Attempt to block undesired key combinations
 */
void blockKeys(KeyEvent event){

  print("${event.keyCode}");
  if(event.keyCode == 27 /* ESC */ ||
    (event.altKey && (event.which == 115 /* F4 */ || event.which == 9 /* Tab */)) ||
    (event.keyCode == 91) /* Windows Key ... doesn't work of course */) {
    event.preventDefault();
    event.stopImmediatePropagation();
    event.stopPropagation();
  }
}

void close(MouseEvent event) {
  (querySelector('dialog') as DialogElement).close('');
}
/**
 * On click from 'Submit' for ID, this will pull the ID and right now just moves on.
 */
void getID(MouseEvent event) {
  String ID = (querySelector('#idText') as TextInputElement).value;

  if(ID=="" || ID.length < 5){
    DialogElement dialog = querySelector('dialog') as DialogElement;
    dialog.showModal();
  }
  else{

    /* TODO: Verify this ID by sending it back to Supervisor */
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
void gotoReview(MouseEvent event, Ballot b) {

  /* Set the delta to purposefully get to the review page */
  update(event, b.size()-b.getCurrentPage(), b);
}

void update(MouseEvent event, int delta, Ballot b) {

  /* Display the new page (either next or previous) */
  if(b.getCurrentPage() != b.size()) {
    /* Record information on currentPage in the Ballot */
    record(b);
    display(event, b.getCurrentPage() + delta, b);
  } else {
    review(event, b.getCurrentPage()+delta, b);
  }
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
 * Renders the pageToDisplay in the Ballot as HTML in the UI as a "reviewed" page
 */
void review(MouseEvent event, int pageToDisplay, Ballot b) {

  if (pageToDisplay < 0) pageToDisplay = 0;

  if(pageToDisplay >= b.size()) {
    displayReviewPage(b);
    b.updateCurrentPage(b.size());
  } else {
    reviewRace(b.getRace(pageToDisplay));
    b.updateCurrentPage(pageToDisplay);
  }
}

void reviewRace(Race race) {

  /* Clear all other HTML */

  /* If hide all other buttons except "Return to Review" */
  querySelector("#Next").style.visibility = "hidden";
  querySelector("#Skip").style.visibility = "hidden";
  querySelector("#Review").style.visibility = "visible";


  /* Display the current race info */
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
  querySelector("#Review").style.visibility = "hidden";

  /* If nothing has already been selected show "skip" , otherwise "next" */
  if(race.hasVoted()) {
    querySelector("#Next").style.visibility = "visible";
    querySelector("#Skip").style.visibility = "hidden";
  }
  else {
    querySelector("#Next").style.visibility = "hidden";
    querySelector("#Skip").style.visibility = "visible";
  }

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
Future<Ballot> loadBallot() async {

  String ballotXML = (await chrome.storage.local.get('XML'))['XML'];

  if (ballotXML == null) {
    print("The file was not loaded properly!");
    return null;
  }

  print("Loaded the ballot...");
  Ballot ballot = new Ballot();
  print("Parsing the ballot!");
  XmlDocument xmlDoc = await parse(ballotXML);
  print("Parsed the ballot!");
  print("Loading the ballot from XML...");
  ballot.loadFromXML(xmlDoc);

  return ballot;
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

  String toString(){
    return "Name: $_identifier, Group: $groupAssociation, Voted Status: $_voted\n";
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

  String toString(){
    String strRep = "Race: $_title";
    strRep += "\n\tText: $text";
    strRep += "\n\tOptions: \n";

    for(Option option in _options) {
      strRep += "\t\t$option";
    }

    strRep += "\nVoted Status: $_voted\n";

    return strRep;
  }

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

    List<XmlElement> raceList = xml.findAllElements("race");

    for (XmlElement race in raceList) {


      String title = race.findElements("title").first.text;
      List<XmlElement> XMLcandidates = race.findElements("candidate");
      List<Option> candidates = new List<Option>();

      for (XmlElement element in XMLcandidates) {
        candidates.add(new Option(element.findElements("name").first.text,
                                  groupAssociation: element.findElements("party").first.text));
      }

      Race currentRace = new Race(title, candidates);
      _races.add(currentRace);

    }

    List<XmlElement> propList = xml.findAllElements("proposition");


    for (XmlElement prop in propList) {

      String title = prop.findElements("title").first.text;
      String text = prop.findElements("propositionText").first.text;

      List<Option> responses = new List<Option>();
      responses.add(new Option("Yes"));
      responses.add(new Option("No"));

      Race currentRace = new Race(title, responses, text: text);
      _races.add(currentRace);

    }

  }

  String toString(){
    String strRep="";

    for(Race race in _races) {
      strRep += "$race\n";
    }

    strRep += "\n";

    return strRep;
  }
}


