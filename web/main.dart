/**
 * The main guts of the Voting Session UI (current project name 'VoteBoxUI')
 */

import 'dart:html' hide XmlDocument;
import 'dart:async';
import 'package:xml/xml.dart';
import 'package:chrome/chrome_app.dart' as chrome;

main() async {

  /* Block undesirable key combinations */
  document.onKeyPress.listen(blockKeys);
  document.onKeyDown.listen(blockKeys);
  document.onKeyUp.listen(blockKeys);

  Ballot ballot;

  /* Load the Ballot from the XML file reference passed through localdata */
  print("Loading ballot...");
  ballot = await loadBallot();
  print("Ballot has ${ballot.size()} races and propositions detected.");

  /* Set up listeners for the different buttons clicked */
  querySelector('#ID').onClick.listen(getID);
  /* TODO: perhaps check for 'enter key' event on textinputelement */

  querySelector('#okay').onClick.listen(close);

  querySelector('#button_begin').onClick.listen(gotoFirstInstructions);

  querySelector('#Back').onClick.listen(gotoInfo);
  querySelector('#Begin').onClick.listen((MouseEvent e) => beginElection(e, ballot));

  /* TODO straight party? */

  querySelector('#Previous').onClick.listen((MouseEvent e) => update(e, -1, ballot));
  querySelector('#Next').onClick.listen((MouseEvent e) => update(e, 1, ballot));

  querySelector('#Review').onClick.listen((MouseEvent e) => gotoReview(e, ballot));

  querySelector('#finishUp').onClick.listen((e) => intermediateSubmitScreen);
  querySelector('#endVoting').onClick.listen((e) => () async {
      await confirmScreen();
      chrome.app.window.current().close();
  });
}

/**
 * Attempt to block undesired key combinations
 */
void blockKeys(KeyEvent event){

  if(event.keyCode == 27 /* ESC */ ||
    (event.altKey && (event.which == 115 /* F4 */ || event.which == 9 /* Tab */)) ||
    (event.keyCode == 91) /* Windows Key ... doesn't work of course */) {
    event.preventDefault();
    event.stopImmediatePropagation();
    event.stopPropagation();
  }
}

/**
 * Closes the modal dialog
 */
void close(MouseEvent event) {
  (querySelector('dialog') as DialogElement).close('');
}
/**
 * On click from 'Submit' for ID, this will pull the ID and right now just moves on.
 */
void getID(MouseEvent event) {
  String ID = (querySelector('#idText') as TextInputElement).value;

  /* TODO check for non-numerals and validate with Supervisor */
  if(ID=="" || ID.length < 5){
    DialogElement dialog = querySelector('dialog') as DialogElement;
    dialog.showModal();
  }
  else{

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
void gotoReview(MouseEvent e, Ballot b) {

  /* Set the delta to purposefully get to the review page */
  update(e, b.size()-b.getCurrentPage(), b);
}

void update(MouseEvent event, int delta, Ballot b) {

  /* Display the new page (either next or previous) */
  if(b.getCurrentPage() != b.size()) {
    /* Record information on currentPage in the Ballot */
    record(b);
    display(b.getCurrentPage() + delta, b);
  } else {
    review(event, b.getCurrentPage()+delta, b);
  }
}

/**
 * Records the current selection state of the current Race in the Ballot
 */
void record(Ballot b){
  /* Get the "votes" collection of elements from this page */
  Iterable<DivElement> selected;

  /* Get the currently selected candidate button(s) on the page */
  selected = (querySelector("#votes").querySelectorAll(".option") as ElementList<DivElement>).where((DivElement el) => isSelected(el));

  /* There should never be more than one selected radio button... */
  if(selected.length == 1) {

    /* Mark the Option in this Race with the selection's name */
    b.getRace(b.getCurrentPage()).markSelection(selected.elementAt(0).querySelector(".optionIdentifier").text);
  }
  else if (selected.length == 0){

    /* If nothing is selected, note it */
    b.getRace(b.getCurrentPage()).noSelection();
  }

}

/**
 * Returns the checked state of this radio button
 */
bool isSelected(DivElement e) {
  return (e.querySelector(".vote") as InputElement).checked;
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

    /* Update progress */
    querySelector("#progress").text = "${pageToDisplay+1} of ${b.size()}";

    Race race = b.getRace(pageToDisplay);

    reviewRace(race);
    b.updateCurrentPage(pageToDisplay);
  }
}

void reviewRace(Race race) {

  /* Make review div invisible */
  querySelector("#reviews").style.visibility = "hidden";
  querySelector("#reviews").style.visibility = "hidden";
  querySelector("#reviews").style.display = "none";

  querySelector("#progress").style.visibility = "visible";

  /* Regenerate this page and check correct boxes */
  displayRace(race);

  /* Hide all other buttons except "Return to Review" */
  querySelector("#Previous").style.visibility = "hidden";
  querySelector("#Next").style.display = "none";
  querySelector("#finishUp").style.display = "none";

  querySelector("#Review").style.display = "block";
  querySelector("#Review").style.visibility = "visible";

}

/**
 * Triggers on 'Next' after 'Begin', displays the first race in the election
 */
void beginElection(MouseEvent e, Ballot b) {

  /* Erase first instructions */
  querySelector("#first_instructions").style.display="none";

  querySelector("#Back").style.display="none";
  querySelector("#Previous").style.visibility = "hidden";

  querySelector("#Begin").style.display="none";

  /* Display this button */
  querySelector("#Next").style.visibility="visible";
  querySelector("#Next").style.display="block";

  /* Set up race div */
  querySelector("#VotingContentDIV").style.visibility = "visible";
  querySelector("#VotingContentDIV").style.display = "block";

  /* Display the first race */
  display(0, b);
}



/**
 * Renders the pageToDisplay in the Ballot as HTML in the UI
 */
void display(int pageToDisplay, Ballot b) {

  if (pageToDisplay < 0) pageToDisplay = 0;

  if(pageToDisplay >= b.size()) {

    displayReviewPage(b);
    b.updateCurrentPage(b.size());
  } else {

    /* Update progress */
    querySelector("#progress").text = "${pageToDisplay+1} of ${b.size()}";

    if (pageToDisplay>0)
      querySelector("#Previous").style.visibility = "visible";
    else
      querySelector("#Previous").style.visibility = "hidden";

    Race race = b.getRace(pageToDisplay);

    /* Show proper button */
    ButtonElement nextButton = querySelector("#Next");
    nextButton.style.visibility = "visible";

    /* If nothing has already been selected show "skip" , otherwise "next" (maybe relevant for straight party) */
    if(race.hasVoted()) {
      nextButton.className = "next";
      nextButton.text = "Next";
    }
    else {
      nextButton.className = "skip";
      nextButton.text = "Skip";
    }

    displayRace(race);
    b.updateCurrentPage(pageToDisplay);
  }
}

/**
 * Renders this Race on the UI as HTML
 */
void displayRace(Race race) {

  DivElement votingContentDiv = querySelector("#VotingContentDIV");

  /* Clear div of previous race and title */
  querySelector("#titles").remove();
  querySelector("#votes").remove();

  /* Add new title div */
  DivElement titleDiv = new DivElement();

  titleDiv.id = "titles";

  /* Create a bunch of divs for the different elements */
  if (race.type == "proposition") {

    DivElement propTitleDiv = new DivElement();
    DivElement propInstDiv = new DivElement();
    DivElement raceTitleDiv = new DivElement();

    propTitleDiv.id = "propTitle";
    propTitleDiv.className = "propTitle";
    propTitleDiv.text = race.title;
    titleDiv.append(propTitleDiv);
    titleDiv.appendHtml("<br>");

    propInstDiv.id = "propInst";
    propInstDiv.text = "Choose yes or no.";
    titleDiv.append(propInstDiv);
    titleDiv.appendHtml("<br>");

    raceTitleDiv.id = "raceTitle";
    raceTitleDiv.className = "propText";
    raceTitleDiv.text = race.text;
    titleDiv.append(raceTitleDiv);
  }
  else if (race.type == "race") {

    DivElement raceTitleDiv = new DivElement();
    DivElement raceInstDiv = new DivElement();

    raceTitleDiv.id = "raceTitle";
    raceTitleDiv.className = "raceTitle";
    raceTitleDiv.text = race.title;
    titleDiv.append(raceTitleDiv);
    titleDiv.appendHtml("<br>");

    raceInstDiv.id = "raceInst";
    raceInstDiv.text = "Vote for 1.";
    titleDiv.append(raceInstDiv);
  }

  /* Add new race div */
  DivElement votesDiv = new DivElement();
  votesDiv.id = "votes";

  /* Display the current race info */
  for (Option o in race.options) {

    /* Starts from 1 */
    int currentIndex = race.options.indexOf(o)+1;

    /* Create a div for each option */
    DivElement optionDiv = new DivElement();

    /* Set up the id and class */
    optionDiv.id = "option$currentIndex";
    optionDiv.className = "option";
    optionDiv.style.border = "1px solid black;";
    optionDiv.onClick.listen((MouseEvent e)=>respondToClick(e,race));

    /* Create voteButton div */
    DivElement voteButtonDiv = new DivElement();
    voteButtonDiv.className = "voteButton";

    /* Set up label element */
    LabelElement voteButtonLabel = new LabelElement();

    /* Set up the radio/checkbox */
    InputElement voteInput = new InputElement();
    voteInput.name="vote";
    voteInput.type="radio";
    voteInput.id="radio1";
    voteInput.className = "vote";
    voteInput.checked = o.wasSelected();

    /* Set up image */
    ImageElement voteButtonImage = new ImageElement();
    voteButtonImage.src = "images/check_selected copy-01.png";

    /* Append the radiobutton and image to this label so that it can be added as a button */
    voteButtonLabel.append(voteInput);
    voteButtonLabel.append(voteButtonImage);

    voteButtonDiv.append(voteButtonLabel);

    /* Now set up the candidate and party name divs */
    DivElement nameDiv = new DivElement();
    nameDiv.id = "c$currentIndex";
    nameDiv.style.color = o.wasSelected() ? "white" : "black";
    nameDiv.className = "optionIdentifier";
    nameDiv.text = o.identifier;

    DivElement partyDiv = new DivElement();
    partyDiv.id = "p$currentIndex";
    partyDiv.style.color = o.wasSelected() ? "white" : "black";
    partyDiv.className = "optionGroup";
    partyDiv.text=(o.groupAssociation != null) ? o.groupAssociation : "";

    /* Add all of these to the optiondiv and then add this option to the current vote div */
    optionDiv.append(voteButtonDiv);
    optionDiv.append(nameDiv);
    optionDiv.append(partyDiv);

    votesDiv.append(optionDiv);
  }

  /* Append this to the page */
  votingContentDiv.append(titleDiv);
  votingContentDiv.append(votesDiv);

  /* Final setup */
  votingContentDiv.style.display = "block";
  votingContentDiv.style.visibility = "visible";
  votingContentDiv.className = "votingInstructions";
}

/**
 *
 */
void respondToClick(MouseEvent e, Race race) {

  /* Toggle the target of the click */
  InputElement target = ((e.currentTarget as Element).querySelector(".vote") as InputElement);
  target.checked = !target.checked;

  /* Add the image */

  /* Now update this Race */
  if(target.checked) {
    race.markSelection((e.currentTarget as Element).querySelector(".optionIdentifier").text);

    /* Update the button as well if in */
    if (querySelector("#Next").style.display == "block" && querySelector("#Next").style.visibility == "visible") {
      querySelector("#Next").className = "next";
      querySelector("#Next").text = "Next";
    }
  }
  else {

    /* Update the button as well if in */
    if (querySelector("#Next").style.display == "block" && querySelector("#Next").style.visibility == "visible") {
      querySelector("#Next").className = "skip";
      querySelector("#Next").text = "Skip";
    }

    race.noSelection();
  }

  /* Just redisplay the page to take care of everything */
  displayRace(race);

}

/**
 * Renders the review page for the current state of this Ballot
 */
void displayReviewPage(Ballot b) {

  /* Clear all other HTML */
  querySelector("#VotingContentDIV").style.display = "none";

  /* Hide the progress bar */
  querySelector("#progress").style.visibility = "hidden";

  /* Move these out of the way for finishUp */
  querySelector("#Next").style.display = "none";
  querySelector("#Review").style.display = "none";

  /* Hide this */
  querySelector("#Previous").style.visibility = "hidden";

  /* Display only "Print Your Ballot" button on bottom bar */
  querySelector("#finishUp").style.display = "block";
  querySelector("#finishUp").style.visibility = "visible";

  /* Display review */
  querySelector("#reviews").style.visibility = "visible";
  querySelector("#reviews").style.display = "block";

  DivElement reviewCol1 = querySelector("#review1");
  DivElement reviewCol2 = querySelector("#review2");

  querySelector("#reviewTop").style.visibility = "visible";

  /* Remove all races */
  reviewCol1.querySelectorAll(".race").forEach((Element e) => e.remove());
  reviewCol2.querySelectorAll(".race").forEach((Element e) => e.remove());

  /* Go through all the races and add them to the columns (14 max in each?) */
  for (int i=0; i<b.size(); i++) {

    /* Get the ith race */
    Race currentRace = b.getRace(i);

    /* Create a div for it */
    DivElement raceDiv = new DivElement();
    raceDiv.id = "race${i+1}";
    raceDiv.className = "race";

    /* Set up these divs for it */
    DivElement raceTitle = new DivElement();
    raceTitle.id = "raceTitle${i+1}";
    raceTitle.className = "title";
    raceTitle.innerHtml = "${i+1}. <b>${currentRace.title}</b>";

    DivElement raceBox = new DivElement();
    raceBox.id = "raceSelBox${i+1}";

    raceBox.className = currentRace.hasVoted() ? "sel" : "noSel";

    DivElement raceSelection = new DivElement();
    raceSelection.id = "raceSel${i+1}";
    raceSelection.className = "raceSel";
    raceSelection.text = currentRace.hasVoted() ?
                          currentRace.getSelectedOption().identifier :
                          "You did not vote for anyone. If you want to vote, touch here.";

    DivElement partySelection = new DivElement();
    partySelection.id = "party${i+1}";
    partySelection.className = "party";
    partySelection.text = currentRace.hasVoted() && (currentRace.getSelectedOption().groupAssociation != null) ?
                            currentRace.getSelectedOption().groupAssociation :
                            "";

    raceBox.append(raceSelection);
    raceBox.appendHtml("<strong>${partySelection.outerHtml}</strong>");

    raceDiv.append(raceTitle);
    raceDiv.append(raceBox);

    /* Set up a listener for click on raceDiv */
    raceDiv.onClick.listen((MouseEvent e) => review(e, i, b));

    /* Send to correct column */
    querySelector("#review${(i<14) ? "1" : "2"}").append(raceDiv);

  }

  reviewCol1.style.visibility = "visible";
  reviewCol2.style.visibility = "visible";

}

void intermediateSubmitScreen(){

  print("Submitting!");

  /* Get rid of original "Print Your Ballot" button on bottom bar */
  querySelector('#finishUp').style.display = "none";
  querySelector('#finishUp').style.visibility = "hidden";

  /* Undisplay review */
  querySelector('#reviews').style.visibility = "hidden";
  querySelector('#reviews').style.display = "none";

  /* Display submit screen */
  querySelector('#submitScreen').style.visibility = "visible";
  querySelector('#submitScreen').style.display = "block";

}


Future confirmScreen() async {

  print("Confirming!");
  querySelector('#submitScreen').style.visibility = "hidden";
  querySelector('#submitScreen').style.display = "none";

  querySelector('#confirmation').style.visibility = "visible";
  querySelector('#confirmation').style.display = "block";

  /* Await the construction of this future so we can quit */
  return new Future.delayed(const Duration(seconds: 5), () => '5');

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

  print("Loaded the ballot XML...");
  Ballot ballot = new Ballot();

  print("Parsing the ballot XML...");
  XmlDocument xmlDoc = await parse(ballotXML);

  print("Parsed the ballot XML!");

  print("Loading the ballot from XML...");
  ballot.loadFromXML(xmlDoc);

  return ballot;
}


/**
 *
 */
class Option {
  String identifier;
  String groupAssociation;
  bool _voted=false;

  Option(this.identifier, {this.groupAssociation});

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
    return "Name: $identifier, Group: $groupAssociation, Voted Status: $_voted\n";
  }
}


/**
 *
 */
class Race {

  String title;
  List<Option> options;
  String text;
  String type;
  bool _voted=false;

  Race(this.title, this.options, this.type, {this.text});

  bool hasVoted() {
    return _voted;
  }

  void markSelection(String identifier) {
    _voted = true;

    for(Option o in options) {
      o.unmark();

      if (o.identifier == identifier)
        o.mark();
    }
  }

  Option getSelectedOption(){
    if (_voted) {
      return options.firstWhere((Option o) => o._voted);
    }

    return null;
  }

  void noSelection(){
    _voted = false;

    for(Option o in options) {
      o.unmark();
    }

  }

  String toString(){
    String strRep = "Race: $title";
    strRep += "\n\tText: $text";
    strRep += "\n\tOptions: \n";

    for(Option option in options) {
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

      Race currentRace = new Race(title, candidates, "race");
      _races.add(currentRace);

    }

    List<XmlElement> propList = xml.findAllElements("proposition");


    for (XmlElement prop in propList) {

      String title = prop.findElements("title").first.text;
      String text = prop.findElements("propositionText").first.text;

      List<Option> responses = new List<Option>();
      responses.add(new Option("Yes"));
      responses.add(new Option("No"));

      Race currentRace = new Race(title, responses, "proposition", text: text);
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


