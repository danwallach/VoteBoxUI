/**
 * The main guts of the Voting Session UI (current project name 'VoteBoxUI')
 */

import 'dart:html' hide XmlDocument;
import 'dart:async';
import 'package:xml/xml.dart';
import 'package:chrome/chrome_app.dart' as chrome;
import 'dart:math';
import 'dart:convert' show JSON;
import 'dart:collection';

List<int> raceChangeList = new List<int>();
HashMap<int,String> alreadyChangedMap = new HashMap<int, String>();
HashMap<int,String> voterIntentMap = new HashMap<int, String>();
List<String> typeOfChange = new List<String>();
bool inlineConfirmation;
bool endOfBallotReview;
bool dialogConfirmation;
bool userCorrection;
String voteFlippingType;
String currentPage="Options Page";
Ballot actuallyCastBallot;
Logger logger = new Logger();
String ID;


main() async {

  chrome.app.window.current().fullscreen();

  /* Block undesirable key combinations */
  document.onKeyPress.listen(blockKeys);
  document.onKeyDown.listen(blockKeys);
  document.onKeyUp.listen(blockKeys);

  /* Load the Ballot from the XML file reference passed through localdata */
  print("Loading ballot...");
  actuallyCastBallot = await loadBallot();
  print("Ballot has ${actuallyCastBallot.size()} races and propositions detected.");

  /*****************************************************************************************************************************\
                                                      OPTIONS PAGE
  \*****************************************************************************************************************************/
  /* If review type option is chosen... */
  querySelectorAll('input[name=\"reviewType\"]').onClick.listen(
          (MouseEvent e){
            /* Set the inlineConfirmation while we're here */
            inlineConfirmation = ((querySelector('#reviewTypeInline') as RadioButtonInputElement).checked || (querySelector('#reviewTypeBoth') as RadioButtonInputElement).checked);
            querySelector('#inlineTypeOption').style.visibility = inlineConfirmation ? "visible":"hidden";
            querySelector('#inlineTypeOption').style.display = inlineConfirmation ? "block":"none";
          }
  );

  /* Check for one of the main mode buttons to be clicked */
  querySelectorAll('.changeOptionsButton').onClick.listen(

          (MouseEvent e){

            /* Make all the button font weights normal again */
            (querySelectorAll('.changeOptionsButton') as ElementList<ButtonElement>).forEach(
                (ButtonElement b) {
                  b.style.fontWeight = "normal";
                }
            );

            /* Bold the selected one */
            ButtonElement buttonClicked = (e.currentTarget as ButtonElement);
            buttonClicked.style.fontWeight = "bold";

            querySelector('#confirmOptions').style.visibility = "visible";
            querySelector('#reviewOptions').style.visibility = "visible";

            querySelector('#changeOptionsSelection').innerHtml = "You've selected <font color=\"red\">${buttonClicked.text}";

            voteFlippingType = buttonClicked.text.trim();


            querySelector("#changeOptions").style.visibility = (voteFlippingType != "No Vote Changes") ?  "visible" :"hidden";
            querySelector("#changeOptions").style.display = (voteFlippingType != "No Vote Changes") ?  "block" :"none";
            querySelector('#reviewOptions').style.marginTop = (voteFlippingType != "No Vote Changes") ?  "0" :"7%";
          }
  );

  /* Go to auth screen once options are set up*/
  querySelector('#confirmOptions').onClick.listen(
      (MouseEvent e){
        recordOptions();
        querySelector('#options').style.display ="none";
        querySelector('#auth').style.visibility="visible";
        currentPage="Authentication Page";
      }
  );

  /*****************************************************************************************************************************\
                                                    END OPTIONS PAGE
  \*****************************************************************************************************************************/

  querySelector('#ID').onClick.listen(getID);
  /* TODO: perhaps check for 'enter key' event on textinputelement */

  querySelector('#okay').onClick.listen(
          (MouseEvent event) {
            logger.logEvent(event);
            (querySelector('#IDdialog') as DialogElement).close('');
          }
  );

  querySelector('#button_begin').onClick.listen(gotoFirstInstructions);

  querySelector('#Back').onClick.listen(gotoInfo);
  querySelector('#Begin').onClick.listen(beginElection);

  /* TODO straight party? */

  querySelector('#Previous').onClick.listen((MouseEvent e) => update(e, -1));
  querySelector('#Next').onClick.listen((MouseEvent e) => update(e, 1));

  querySelector('#Review').onClick.listen(gotoReview);

  querySelector('#finishUp').onClick.listen(submitScreen);

  querySelector('#returnToBallot').onClick.listen(returnToBallot);

  querySelector('#endVoting').onClick.listen(endVoting);


}

/**
 *
 */
void recordOptions(){

  /* Gets the first location selected */
  RadioButtonInputElement selected = (querySelectorAll('input[name=\"location\"]') as ElementList<RadioButtonInputElement>).firstWhere(
          (RadioButtonInputElement e){ return e.checked;}
  );

  String labelSelectionStr = querySelector('label[for=\"${selected.id}\"]').text;

  selected = (querySelectorAll('input[name=\"number\"]') as ElementList<RadioButtonInputElement>).firstWhere(
          (RadioButtonInputElement e){ return e.checked;}
  );

  String numStr = querySelector('label[for=\"${selected.id}\"]').text;

  int numToChange = int.parse( numStr.substring(numStr.length-2,numStr.length-1));

  Random random = new Random();

  /* Get a section of races to change */
  switch(labelSelectionStr){

    /* Add the appropriate race numbers to the raceChangeSet */

    /* First 13 races */
    case "Top of Ballot":     for(int i=0; i<13; i++){ raceChangeList.add(i); }
                              break;

    /* Last 14 races */
    case "Bottom of Ballot":  for(int i=13; i<27; i++){ raceChangeList.add(i); }
                              break;

    /* 1-7 and 15-21 */
    case "Top of Screen":     for(int i=0; i<8; i++){ raceChangeList.add(i); }
                              for(int i=13; i<21; i++){ raceChangeList.add(i); }
                              break;

    /* 6-13 and 20-27 */
    case "Bottom of Screen":  for(int i=5; i<13; i++){ raceChangeList.add(i); }
                              for(int i=19; i<27; i++){ raceChangeList.add(i); }
                              break;

    /* 1-7 */
    case "Top Left":          for(int i=0; i<8; i++){ raceChangeList.add(i); }
                              break;

    /* 14-21 */
    case "Top Right":         for(int i=13; i<21; i++){ raceChangeList.add(i); }
                              break;

    /* 20-27 */
    case "Bottom Right":      for(int i=19; i<27; i++){ raceChangeList.add(i); }
                              break;

    /* 6-13 */
    case "Bottom Left":       for(int i=5; i<13; i++){ raceChangeList.add(i); }
                              break;

  }

  /* Get the type of change and insert appropriately into typeOfChange list */
  selected = (querySelectorAll('input[name=\"changeType\"]') as ElementList<RadioButtonInputElement>).firstWhere(
          (RadioButtonInputElement e){ return e.checked;}
  );

  labelSelectionStr = querySelector('label[for=\"${selected.id}\"]').text;

  /* If it's all changes */
  if (labelSelectionStr == "Change Selection") {

    /* Go through the list of races */
    for (int i = 0; i < raceChangeList.length; i++) {

      /* Remove any that have only one candidate */
      if (actuallyCastBallot.getRace(raceChangeList.elementAt(i)).options.length < 2) {

        raceChangeList.removeAt(i);

        /* Expand the range forward as long as we aren't already at the end */
        if (raceChangeList.elementAt(raceChangeList.length)<actuallyCastBallot.size()) {
          raceChangeList.add(raceChangeList.elementAt(raceChangeList.length) + 1);
        }
        /* Otherwise expand the range backwards as long as we aren't at the beginning */
        else if (raceChangeList.elementAt(0)>0)
        {
          raceChangeList.insert(0, raceChangeList.elementAt(0)-1);
        }
      }
    }
  }

  /* Randomly remove until we get down to the number we want */
  for(int i=random.nextInt(raceChangeList.length); raceChangeList.length>numToChange; i=random.nextInt(raceChangeList.length)){
    raceChangeList.remove(raceChangeList.elementAt(i));
  }


  /* Check for combination */
  if (labelSelectionStr == "Combination") {

    Random rng = new Random();

    int numChangeType=0;
    int numNoSelectionType=0;

    /* Trying to randomly assign half */
    for(int i=0; i<raceChangeList.length;i++){

      int rand = rng.nextInt(2);

      /* Checks if either this type was selected or it has to be selected */
      if(rand == 0 && numChangeType <= raceChangeList.length ~/ 2 && actuallyCastBallot.getRace(raceChangeList.elementAt(i)).options.length >= 2) {

          typeOfChange.add("Change Selection");
          numChangeType++;

      } else {

        /* If we're trying to force this race */
        //if(numNoSelectionType == raceChangeList.length - raceChangeList.length ~/ 2) {

        //} else {
          typeOfChange.add("No Selection");
          numNoSelectionType++;
        //}
      }

    }

  } else {

    /* Otherwise just put the text directly in */
    for(int i=0; i<raceChangeList.length; i++) {
      typeOfChange.add(labelSelectionStr);
    }
  }


  /* Set booleans for endOfBallotReview, inlineConfirmation, dialogConfirmation */
  endOfBallotReview   = ( (querySelector('#reviewTypeEndOfBallot') as RadioButtonInputElement).checked ||
                          (querySelector('#reviewTypeBoth') as RadioButtonInputElement).checked  );

  inlineConfirmation  = ( (querySelector('#reviewTypeInline') as RadioButtonInputElement).checked ||
                          (querySelector('#reviewTypeBoth') as RadioButtonInputElement).checked  );

  dialogConfirmation  =   (querySelector('#inlineTypePopup') as RadioButtonInputElement).checked;

  userCorrection      =   (querySelector('#correctOn') as RadioButtonInputElement).checked;


  print("Options: \nraceChangeList: $raceChangeList\nchangedSet: $alreadyChangedMap\ntypeOfChange: $typeOfChange\ninlineConfirmation:"+
  "$inlineConfirmation\nendOfBallotReview: $endOfBallotReview\ndialogConfirmation: $dialogConfirmation\nuserCorrection: $userCorrection\nvoteFlippingType: $voteFlippingType");


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
 * On click from 'Submit' for ID, this will pull the ID and right now just moves on.
 */
void getID(MouseEvent event) {

  logger.logEvent(event);

  String ID = (querySelector('#idText') as TextInputElement).value;

  /* TODO check for non-numerals and validate with Supervisor */
  if(ID=="" || ID.length < 5){
    DialogElement dialog = querySelector('#IDdialog') as DialogElement;
    dialog.showModal();
  }
  else{
    ID = querySelector("#idText").text;
    querySelector("#info").style.visibility="visible"; //shows election information page or start
    querySelector("#ID").style.display="none"; //hides the elements on the authentication page
    querySelector("#enterID").style.display="none";
    querySelector("#idText").style.display="none";
    currentPage = "Information Page";
  }

}

/**
 * Triggers on 'Begin' and renders the 'First Instructions' page
 */
void gotoFirstInstructions(MouseEvent event) {
  logger.logEvent(event);
  querySelector("#first_instructions").style.display="block"; //de-invisibles
  querySelector("#first_instructions").style.visibility="visible"; //displays instructions
  querySelector("#Back").style.visibility="visible"; //shows the back button that takes you to the election info page
  querySelector("#Begin").style.visibility="visible"; //shows the button that is pressed to start voting
  querySelector("#info").style.display="none"; //makes the instructions invisible
  currentPage = "First Instructions Page";
}

/**
 * Triggers on 'Back' and renders the 'Instructions' page
 */
void gotoInfo(MouseEvent event) {
  logger.logEvent(event);
  querySelector("#Begin").style.visibility="hidden"; //hides the begin and back buttons shown on the instructions page
  querySelector("#Back").style.visibility="hidden";
  querySelector("#first_instructions").style.display="none"; //makes the instructions invisible
  querySelector("#info").style.display="block"; //shows election information page or start
  currentPage = "Information Page";
}

/**
 * Triggers on 'Return to Review' and re-renders the 'Review' page
 */
void gotoReview(MouseEvent e) {


  /* Set the delta to purposefully get to the review page */
  update(e, actuallyCastBallot.size()-actuallyCastBallot.getCurrentPage());
}

void update(MouseEvent event, int delta) {

  logger.logEvent(event);

  /* Display the new page (either next or previous) */
  if(actuallyCastBallot.getCurrentPage() != actuallyCastBallot.size()) {


    /* Record information on currentPage in the Ballot */
    record(actuallyCastBallot);

    /* If the inline confirmation is enabled, display the inline first, assuming we're moving forward */
    if(inlineConfirmation && delta>0) {

      /* Change vote if we're voteflipping and progressing */
      if(voteFlippingType == "Vote Changes During Voting"){

        /* This should only randomly flip the vote if it hasn't been flipped before, otherwise flip to previously
         * selected flip chosen by changeVote for this Race */
        changeVote(actuallyCastBallot.getCurrentPage());
      }

      /* Redisplay the current page with updated information
       * This is so popup can see updated information. Inline screen can just clear this out.
       */
      display(actuallyCastBallot.getCurrentPage());

      /* Need to re-hide back and next */
      if(actuallyCastBallot.getCurrentPage()+delta >= actuallyCastBallot.size()) {
        querySelector("#Next").style.display = "none";
        querySelector("#Previous").style.visibility = "hidden";

      }

      currentPage = "Race ${actuallyCastBallot.getCurrentPage()+1} Inline Confirmation";

      /* Display popup or inline screen -- always moving forward 1 */
      displayInlineConfirmation(delta);


    } else {
      /* Inline confirmation is disabled or "Return to Review" or "Previous" button hit */
      /* Just display the next screen */
      display(actuallyCastBallot.getCurrentPage() + delta);

    }


    /* If we're on the review page, review the race */
  } else {
    review(event, actuallyCastBallot.getCurrentPage()+delta);
  }

}

/**
 * Mutates actuallyCastBallot, flipping races determined by raceChangeList
 */
void changeVotes(){

  for(int raceToChange in raceChangeList){
    changeVote(raceToChange);
  }

}

/**
 *
 */
void changeVote(int raceToChangeIndex) {

  /* Get the currently selected (recorded) vote and see if it's part of the raceChangeSet */
  /* Also make sure it hasn't yet been changed (e.g. once during inline before final review) with userCorrection */
  if(raceChangeList.contains(raceToChangeIndex) && !(userCorrection && alreadyChangedMap.containsKey(raceToChangeIndex))) {

    /* If not already changed, change it */
    if(!alreadyChangedMap.containsKey(raceToChangeIndex)) {

      /* Check what type of change  for the current index */
      if (typeOfChange.elementAt(raceChangeList.indexOf(raceToChangeIndex)) == "Change Selection") {
        changeSelection(actuallyCastBallot.getRace(raceToChangeIndex));
        alreadyChangedMap[raceToChangeIndex] = actuallyCastBallot.getRace(raceToChangeIndex).getSelectedOption().identifier;
      } else {
        actuallyCastBallot.getRace(raceToChangeIndex).noSelection();
        alreadyChangedMap[raceToChangeIndex] = "";
      }


    } else {
      /* Change it back */
      if (typeOfChange.elementAt(raceChangeList.indexOf(raceToChangeIndex)) == "Change Selection") {
        actuallyCastBallot.getRace(raceToChangeIndex).markSelection(alreadyChangedMap[raceToChangeIndex]);
      } else {
        actuallyCastBallot.getRace(raceToChangeIndex).noSelection();
      }
    }

  }

}

/**
 *
 */
void changeSelection(Race raceToChange) {

  int raceLength = raceToChange.options.length;
  Random rng = new Random();

  /* If it's voted already, have to make sure to actually change it to something else (what if there's only one option?) */
  if(raceToChange.hasVoted()) {

    int currentIndex = raceToChange.options.indexOf(raceToChange.getSelectedOption());
    int i;

    /* Generate random ints in range until we get something different */
    for(i=rng.nextInt(raceLength); i==currentIndex; i=rng.nextInt(raceLength));

    raceToChange.markSelection(raceToChange.options.elementAt(i).identifier);

  } else {

    /* Get a random integer from 0 to length-1 */
    int randIndex = rng.nextInt(raceLength);

    /* Select this random option */
    raceToChange.markSelection(raceToChange.options.elementAt(randIndex).identifier);
  }

}


/**
 *
 */
void displayInlineConfirmation(int delta){

  if(dialogConfirmation) {
    displayDialogConfirmation(delta);
  } else {
    displayIntermediateConfirmation(delta);
  }

}

/**
 *
 */
void displayDialogConfirmation(int delta) {

  DialogElement verifyDialog = querySelector('#verifyDialog');

  querySelector("#VotingContentDIV").style.top = "175px";

  verifyDialog.innerHtml = "";

  Race currentRace = actuallyCastBallot.getRace(actuallyCastBallot.getCurrentPage());

  /* Show an appropriate confirmation message */
  verifyDialog.appendHtml(currentRace.hasVoted()?
      "<p>You selected <br><b>${currentRace.getSelectedOption().identifier}\t${currentRace.getSelectedOption().groupAssociation}</b><br>Is this correct?</p>" :
      "<p>You did not select any"+((currentRace.type == "race")? "one":"thing")+".<br><br>Is this correct?</p>");

  /* Build the buttons */
  ButtonElement dialogNo = new ButtonElement();
  dialogNo.id = "dialogNo";
  dialogNo.className = "dialogButton";
  dialogNo.text = "No";

  ButtonElement dialogYes = new ButtonElement();
  dialogYes.id = "dialogYes";
  dialogYes.className = "dialogButton";
  dialogYes.text = "Yes";

  /* Add them to the dialog */
  verifyDialog.append(dialogNo);
  verifyDialog.append(dialogYes);

  /* Display the notice and listen for button click */
  verifyDialog.showModal();

  /* Close and display the next page if yes */
  dialogYes.onClick.listen(
          (MouseEvent e){
            logger.logEvent(e);
            querySelector("#VotingContentDIV").style.top = "500px";
            verifyDialog.close('');
            display(actuallyCastBallot.getCurrentPage()+delta);
          }
  );

  /* Close this if no */
  dialogNo.onClick.listen(
          (MouseEvent e){
            logger.logEvent(e);
            querySelector("#VotingContentDIV").style.top = "500px";
            verifyDialog.close('');
            display(actuallyCastBallot.getCurrentPage());
            currentPage = "Race ${actuallyCastBallot.getCurrentPage()+1}";
          }
  );
}

/**
 *
 */
void displayIntermediateConfirmation(int delta) {

  bool reviewing = (querySelector("#Review").style.visibility == "visible");

  /* Clear the current page of voting and buttons and display intermediate screen */
  querySelector("#VotingContentDIV").style.display = "none";
  querySelector("#Next").style.visibility = "hidden";
  querySelector("#Previous").style.display = "none";
  querySelector("#Review").style.visibility = "hidden";

  /* Display intermediate screen */
  if(querySelector("#inlineConfirmationDiv") != null) querySelector("#inlineConfirmationDiv").remove();

  Race currentRace = actuallyCastBallot.getRace(actuallyCastBallot.getCurrentPage());

  DivElement inlineConfirmationDiv = new DivElement();
  inlineConfirmationDiv.id = "inlineConfirmationDiv";
  inlineConfirmationDiv.appendHtml(actuallyCastBallot.getRace(actuallyCastBallot.getCurrentPage()).hasVoted()?
  "<p>You selected <br><b>${currentRace.getSelectedOption().identifier}\t${currentRace.getSelectedOption().groupAssociation}</b><br>Is this correct?</p>" :
  "<p>You did not select any"+((currentRace.type == "race")? "one":"thing")+".<br>Is this correct?</p>");

  /* Create the buttons */
  ButtonElement yesButton = new ButtonElement();
  yesButton.id = "Yes";
  yesButton.style.display = "block";
  yesButton.text = "Yes";

  ButtonElement noButton  = new ButtonElement();
  noButton.id = "No";
  noButton.style.display = "block";
  noButton.text = "No";
  noButton.className = reviewing.toString();

  /* Add these buttons in the proper places */
  querySelector("#Bottom").insertBefore(noButton, querySelector("#progress"));
  querySelector("#Bottom").insertBefore(yesButton, querySelector("#Next"));


  querySelector("#Content").append(inlineConfirmationDiv);

  /* Display the next page if yes */
  yesButton.onClick.listen(
          (MouseEvent e){
            logger.logEvent(e);
            querySelector("#inlineConfirmationDiv").style.display = "none";
            querySelector("#Next").style.visibility = "visible";
            querySelector("#Previous").style.display = "block";
            yesButton.style.display = "none";
            noButton.style.display = "none";

            /* Redisplay of everything is handled by display */
            display(actuallyCastBallot.getCurrentPage()+delta);

            querySelector("#Bottom").querySelector("#No").remove();
            querySelector("#Bottom").querySelector("#Yes").remove();
          }
  );

  /* Go back to previous page if no */
  noButton.onClick.listen(
          (MouseEvent e){
            logger.logEvent(e);
            querySelector("#inlineConfirmationDiv").style.display = "none";
            querySelector("#Next").style.visibility = "visible";
            querySelector("#Previous").style.display = "block";
            yesButton.style.display = "none";
            noButton.style.display = "none";

            /* Redisplay of everything is handled by display */
            display(actuallyCastBallot.getCurrentPage());

            /* Need to re-hide back and next */
            if(actuallyCastBallot.getCurrentPage()+delta >= actuallyCastBallot.size() && (e.currentTarget as Element).className == "true") {
              querySelector("#Next").style.display = "none";
              querySelector("#Previous").style.visibility = "hidden";
              querySelector("#Review").style.visibility = "visible";
            }

            querySelector("#Bottom").querySelector("#No").remove();
            querySelector("#Bottom").querySelector("#Yes").remove();


          }
  );

}



/**
 * Records the current selection state of the current Race in the Ballot
 */
void record(Ballot b){
  /* Get the "votes" collection of elements from this page */
  Iterable<DivElement> selected;

  /* Get the currently selected candidate button(s) on the page */
  selected = (querySelector("#votes").querySelectorAll(".option") as ElementList<DivElement>).where(

          (DivElement e) {
            return (e.querySelector(".vote") as InputElement).checked;
          }
  );

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
 * Renders the pageToDisplay in the Ballot as HTML in the UI as a "reviewed" page
 */
void review(MouseEvent event, int pageToDisplay) {

  logger.logEvent(event);

  if (pageToDisplay < 0) pageToDisplay = 0;

  if(pageToDisplay >= actuallyCastBallot.size()) {

    displayReviewPage();

    currentPage = "Review Page";
    actuallyCastBallot.updateCurrentPage(actuallyCastBallot.size());

  } else {

    /* Update progress */
    querySelector("#progress").text = "${pageToDisplay+1} of ${actuallyCastBallot.size()}";

    Race race = actuallyCastBallot.getRace(pageToDisplay);

    reviewRace(race);

    currentPage = "Race ${pageToDisplay+1} Review";

    actuallyCastBallot.updateCurrentPage(pageToDisplay);
  }
}

/**
 *
 */
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
void beginElection(Event e) {

  logger.logEvent(e);
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
  display(0);
  currentPage = "Race 1";
}



/**
 * Renders the pageToDisplay in the Ballot as HTML in the UI
 */
void display(int pageToDisplay) {

  if (pageToDisplay < 0) pageToDisplay = 0;

  /* Displaying the review page */
  if(pageToDisplay >= actuallyCastBallot.size()) {

    /* Since we're going to the review page, flip here */
    if(endOfBallotReview) {
      /* Change all the relevant votes now (unless they've been flipped already) */
      if(voteFlippingType == "Vote Changes During Voting") {
        changeVotes();
      }

      displayReviewPage();
      currentPage = "Review Page";

    } else {
      /* Proceed to printing page (display review to ensure cleanup of voting div, then submitScreen) */
      displayReviewPage();

      currentPage = "Submit Screen";

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

    actuallyCastBallot.updateCurrentPage(actuallyCastBallot.size());

  } else {

    /* Update progress */
    querySelector("#progress").text = "${pageToDisplay+1} of ${actuallyCastBallot.size()}";

    if (pageToDisplay>0)
      querySelector("#Previous").style.visibility = "visible";
    else
      querySelector("#Previous").style.visibility = "hidden";

    Race race = actuallyCastBallot.getRace(pageToDisplay);

    /* Show proper button */
    ButtonElement nextButton = querySelector("#Next");
    nextButton.style.visibility = "visible";
    nextButton.style.display = "block";


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

    currentPage = "Race ${pageToDisplay+1}";
    actuallyCastBallot.updateCurrentPage(pageToDisplay);
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
    partyDiv.text=o.groupAssociation;

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

  logger.logEvent(e);

  /* Toggle the target of the click */
  InputElement target = ((e.currentTarget as Element).querySelector(".vote") as InputElement);
  target.checked = !target.checked;


  /* Now update this Race */
  if(target.checked) {
    race.markSelection((e.currentTarget as Element).querySelector(".optionIdentifier").text);

    /* Do this here so that we can keep track of what was actually clicked vs what we changed */
    /* Check if this race is a flipped one (otherwise we don't have to keep track) */
    if(alreadyChangedMap.containsKey(actuallyCastBallot.getCurrentPage())) {
      voterIntentMap[actuallyCastBallot.getCurrentPage()] = race.getSelectedOption().identifier;
    }

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

    /* Do this here so that we can keep track of what was actually clicked vs what we changed */
    /* Check if this race is a flipped one (otherwise we don't have to keep track) */
    if(alreadyChangedMap.containsKey(actuallyCastBallot.getCurrentPage())) {
      voterIntentMap[actuallyCastBallot.getCurrentPage()] = null;
    }
  }

  /* Just redisplay the page to take care of everything */
  displayRace(race);
}

/**
 * Renders the review page for the current state of this Ballot
 */
void displayReviewPage() {

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
  for (int i=0; i<actuallyCastBallot.size(); i++) {

    /* Get the ith race */
    Race currentRace = actuallyCastBallot.getRace(i);

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
    partySelection.text = currentRace.hasVoted() ?
                            currentRace.getSelectedOption().groupAssociation :
                            "";

    raceBox.append(raceSelection);
    raceBox.appendHtml("<strong>${partySelection.outerHtml}</strong>");

    raceDiv.append(raceTitle);
    raceDiv.append(raceBox);

    /* Set up a listener for click on raceDiv */
    raceDiv.onClick.listen((MouseEvent e) => review(e, i));

    /* Send to correct column */
    querySelector("#review${(i<14) ? "1" : "2"}").append(raceDiv);

  }

  reviewCol1.style.visibility = "visible";
  reviewCol2.style.visibility = "visible";

}

void submitScreen(Event e){

  logger.logEvent(e);

  currentPage = "Submit Screen";

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

void returnToBallot (Event e){

  /* Undisplay submit screen */
  querySelector('#submitScreen').style.visibility = "hidden";
  querySelector('#submitScreen').style.display = "none";

  if(endOfBallotReview) {

    /* Display "Print your ballot" */
    querySelector('#finishUp').style.display = "block";
    querySelector('#finishUp').style.visibility = "visible";

    /* Display review */
    querySelector('#reviews').style.visibility = "visible";
    querySelector('#reviews').style.display = "block";

    gotoReview(e);

  } else {

    display(actuallyCastBallot.size()-1);
  }


}

Future endVoting(Event e) async {
  logger.logEvent(e);
  currentPage = "End Voting Page";
  await confirmScreen();
  chrome.app.window.current().close();
}

Future confirmScreen() async {

  print("Confirming!");
  querySelector('#submitScreen').style.visibility = "hidden";
  querySelector('#submitScreen').style.display = "none";

  querySelector('#confirmation').style.visibility = "visible";
  querySelector('#confirmation').style.display = "block";

  Ballot voteFlippedBallot;

  /* For now set "voterIntent" to "actuallyCast" */
  Ballot voterIntentBallot = new Ballot.fromBallot(actuallyCastBallot);

  /* Print flipping */
  if(voteFlippingType == "Vote Changes After Voting") {

    /* Change the "actuallyCast" and set "voteFlipped" to it because in this case these are the same */
    changeVotes();
    voteFlippedBallot = new Ballot.fromBallot(actuallyCastBallot);

  } else {

    /* Set "voteFlipped" to "actuallyCast" to get what the voter is about to cast */
    voteFlippedBallot = new Ballot.fromBallot(actuallyCastBallot);

    for(int i in alreadyChangedMap.keys) {

      /* Mark voteFlipped in case any flipped races were corrected (so we can reconstruct all flipped) */
      /* Set the ith race to the option that the flipper selected originally */
      if(alreadyChangedMap[i] =="") {
        voteFlippedBallot.getRace(i).noSelection();
      } else {
        voteFlippedBallot.getRace(i).markSelection(alreadyChangedMap[i]);
      }

      /* Mark voterIntent to get all the voter choices before flipping (so we can reconstruct voter choices on
       * nonflipped races. We assume on flipped races that the first selection was the intended selection... */
      if(voterIntentMap[i] != null) {
        voterIntentBallot.getRace(i).markSelection(voterIntentMap[i]);
      } else {
        voterIntentBallot.getRace(i).noSelection();
      }
    }

  }

  logger.logBallot("Vote-Flipped", voteFlippedBallot);
  logger.logBallot("Voter Intent", voterIntentBallot);
  logger.logBallot("Actually Cast", actuallyCastBallot);

  String report = "";

  /* Get and announce the report */
  try {
    report = logger.report();
  }
  catch(exception,stacktrace) {
    print(exception);
    print(stacktrace);
  }

  await contactServer(report, "report");

  await contactServer(actuallyCastBallot.toJSON(), "");

  await contactServer(null, "finish");


  /* Await the construction of this future so we can quit */
  return new Future.delayed(const Duration(seconds: 180), () => '180');
}
/**
 * Sends a string to the server to be handled, initially for printing
 *
 * This version prints silently, but it communicates unsecurely.
 *
 * The plan is to do so by sending the HTML out as a HTTP POST request
 */
Future contactServer(String toSend, String toAppendToURL) async {
  String host = '127.0.0.1';
  String port = '8888';
  String url = "http://$host:$port/"+toAppendToURL;

  print("Called to print silently...");

  //Create the POST request
  HttpRequest request = new HttpRequest();
  request.open('POST', url);
  request.onLoad.listen((event) => print(
      'Request complete ${event.target.responseText}'));

  return request.send(toSend);
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

  Option(this.identifier, {groupAssociation}){
    this.groupAssociation= (groupAssociation==null) ? "" : groupAssociation;
  }
  //Empty option for using in mappings to represent no selection
  Option.empty() : identifier = null, groupAssociation = null;

  bool wasSelected(){
    return _voted;
  }

  void mark() {
    _voted = true;
  }

  void unmark(){
    _voted = false;
  }

  Option.fromOption(Option toCopy) {
    this.identifier = toCopy.identifier;
    this.groupAssociation = toCopy.groupAssociation;
    this._voted = toCopy.wasSelected();
  }

  String toString(){
    return "Name: $identifier, Group: $groupAssociation, Voted Status: $_voted\n";
  }

  String summary(){
    return identifier+" "+groupAssociation;
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

  String summary(){
    return "${_voted ?  this.getSelectedOption().summary() : "No Selection"} [${title}]";
  }

  Race.fromRace(Race toCopy){
    this.title = toCopy.title;
    this.text  = toCopy.text;
    this.type  = toCopy.type;
    this._voted = toCopy.hasVoted();

    this.options = new List<Option>();

    for(Option o in toCopy.options) {
      this.options.add(new Option.fromOption(o));
    }
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
                                  groupAssociation: (element.findElements("party").first.text != null) ?
                                                        element.findElements("party").first.text : ""));
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

  /*
  * For getting a easily convertable list of
  * all the options that have been voted on.
  *
  * This method  was originally created to help out the toMappingList() method,
  * but I expect this will be fairly useful to use in other features in the future
  *
  * An 'EmptyOption' means that the user didn't vote
  **/
  List<Option> toOptionList() {
    List<dynamic> outputList = new List<Option>();
    for (Race race in _races) {
      Option chosenOption = null;

      if (race.hasVoted()) {
        chosenOption = race.getSelectedOption();
        assert (chosenOption.wasSelected == true);

      } else {
        chosenOption = new Option.empty();
        chosenOption.mark();
      }

      outputList.add(chosenOption);
    }
    return outputList;
  }

  /*
  * For getting a easily convertable list of
  * all the races and selections, with each race represented as
  * a map of strings to strings.
  *
  * The map keys will be
  *   'RACE' for the current Race's name (as a String)
  *   'IDENTIFIER' for the chosen Option's identifier (ie name of the person or proposition)
  *   'GROUP' for the chosen Option's group (generally the party of a candidate)
  *
  *
  * An 'EmptyOption' meant that the user didn't vote! We know it's an empty option if
  * BOTH identifier and group are null.
  **/
  List<Map<String, String>> toStringMappingList() {
    List <dynamic> outputList = new List<Map<String, String>>();
    List <dynamic> optionList = this.toOptionList();

    for (int i=0; i<_races.length; i++) {
      Map<dynamic, dynamic> currentMap = new Map<String, String>();

      /**Get the race's title**/
      Race currentRace = _races.elementAt(i);
      String raceName = currentRace.title;
      currentMap['RACE'] = raceName;


      /**Get the identifier and group**/
      Option currentOption = optionList[i];
      assert(currentOption.wasSelected());
      //if (currentOption.identifier == null && currentOption.group == null) {
      //If hasVoted() is true but the identifier and group are BOTH null,
      //then it means that this is an 'EmptyOption' and the user didn't vote
      //}

      //getting the identifier
      if (currentOption.identifier == null) {
        //THIS MEANS THAT THERE WAS NO SUBMITTED VOTE
        currentMap['IDENTIFIER'] = '';
        //if this is null but the group is not null, we have a serious problem
        assert (currentOption.groupAssociation == null);

      } else {
        currentMap['IDENTIFIER'] = currentOption.identifier;
      }

      //getting the group
      if (currentOption.groupAssociation == null) {
        //Either there was no submitted vote (ie identifier is also null),
        //OR the option just didn't have a group
        currentMap['GROUP'] = '';

      } else {
        currentMap['GROUP'] = currentOption.groupAssociation;
        //if this isn't null but the identifier is null, we have as serious problem
        assert (currentOption.identifier != null);
      }

      outputList.add(currentMap);
    }
    return outputList;
  }

  String toJSON() {
    return JSON.encode(this.toStringMappingList());
  }

  String toString(){
    String strRep="";

    for(Race race in _races) {
      strRep += "$race\n";
    }

    strRep += "\n";

    return strRep;
  }

  String summary(){

    String summary = "\n";
    int i=1;

    for(Race race in _races){
      print("$race");
      summary += "\tRace $i: ${race.summary()}\n";
      i++;
    }

    return summary;
  }

  Ballot.fromBallot(Ballot toCopy) {

    this._races = new List<Race>();

    for(int i=0; i<toCopy.size(); i++)
      this._races.add(new Race.fromRace(toCopy.getRace(i)));

    this._currentPage = toCopy.getCurrentPage();
  }

}



/* ============================================================================= *\
                                      LOGGING
\* ============================================================================= */

class EventTrigger {

  String triggerID;
  String triggerClass;
  String triggerType;

  EventTrigger (EventTarget t) {
    Element tE = t as Element;

    triggerID = tE.id;
    triggerClass = tE.className;
    triggerType = tE.nodeName;
  }

  String toString(){
    return "{ID: $triggerID, Class: $triggerClass, Type: $triggerType}";
  }
}


class LogEvent {

  DateTime time;
  EventTrigger source;
  String pageTitle;
  String eventType;

  LogEvent(Event e) {

    time = new DateTime.now();
    source = new EventTrigger(e.currentTarget);
    eventType = e.type;
    pageTitle = currentPage;
  }

  String toString() {
    return "Event Type: $eventType\n\tTime: $time\n\tPage: $pageTitle\n\tTrigger: $source\n";
  }

}

class LogEventPair {
  LogEvent begin;
  LogEvent end;

  LogEventPair(this.begin, this.end);

  String summary(){
    String summary = "";

    summary += "Beginning Event: $begin\n";
    summary += "End Event: $end\n";

    return summary;
  }
}

class LogEventInterval {

  String pageForInterval;
  Duration intervalLength;
  LogEventPair pairForInterval;

  LogEventInterval(LogEvent begin, LogEvent end, this.pageForInterval){
    intervalLength = end.time.difference(begin.time);
    pairForInterval = new LogEventPair(begin, end);
  }

  String summary(){
    String summary = "";
    summary += "Interval Tracked for $pageForInterval:";
    summary += "\n${pairForInterval.summary()}";
    summary += "Duration: ${intervalLength}\n\n";

    return summary;
  }

  LogEventInterval.join(List<LogEventInterval> toJoin, this.pageForInterval){

    this.pairForInterval = new LogEventPair(toJoin.elementAt(0).pairForInterval.begin, toJoin.elementAt(toJoin.length-1).pairForInterval.end);
    this.intervalLength = Duration.ZERO;

    for(LogEventInterval toBeJoined in toJoin) {
      this.intervalLength += toBeJoined.intervalLength;
    }

  }

}

class Logger {

  List<LogEvent> log;
  List<LogEventInterval> intervalLog;
  LinkedHashMap<String, Ballot> ballotLog;

  Logger(){
    log = new List<LogEvent>();
    intervalLog = new List<LogEventInterval>();
    ballotLog = new LinkedHashMap<String, Ballot>();
  }

  void logEvent(Event e){

    log.add(new LogEvent(e));

    int secondToLast = log.length-2;

    /* Check if this is different pageTitle from the one before it */
    if(secondToLast >= 0) {

      if(log.elementAt(log.length-1).pageTitle != log.elementAt(secondToLast).pageTitle) {

        LogEvent ender = log.elementAt(log.length-1);
        LogEvent initiator = log.elementAt(secondToLast);

        /* If this has a different page, then we should find the first event on this page */
        for (int i = secondToLast; (i>=0) && (log.elementAt(i).pageTitle == ender.pageTitle); i--) {
          initiator = log.elementAt(i-1);
        }

        /* Note this will only find contiguous events, which I think makes sense here */
        intervalLog.add(new LogEventInterval(initiator, ender, ender.pageTitle));
      }
    }
  }

  void logBallot(String designation, Ballot b){
    ballotLog[designation] = new Ballot.fromBallot(b);
  }

  String report(){

    String reportString = "";

    reportString += "User PIN: ${ID}\n";

    reportString += "========\n";
    reportString += "OPTIONS\n";
    reportString += "========\n";

    reportString += "Options: \nList of Changed Races: ${raceChangeList.map((int element){ return element+1;})}\n"+
    "Type Of Change: $typeOfChange\nInline Confirmation: ${inlineConfirmation?"On":"Off"}\nEnd of Ballot Review: "+
    "${endOfBallotReview?"On":"Off"}\nType of Inline Confirmation: ${inlineConfirmation ? (dialogConfirmation ? "Pop-up":
    "Intermediate Screen"):"N/A"}\nUser Correction: ${userCorrection?"On":"Off"}\nVote Flipping Type: $voteFlippingType";

    reportString += "\n\n========\n";
    reportString += " EVENTS\n";
    reportString += "========\n";

    /* Include all the logEvents */
    for(LogEvent logEvent in log){
      reportString += logEvent.toString();
    }

    reportString += "\n\n==========\n";
    reportString += "INTERVALS\n";
    reportString += "==========\n";


    for(LogEventInterval interval in intervalLog) {
      reportString += "\n" + interval.summary();
    }

    reportString += "\n\n======================\n";
    reportString += "CONSOLIDATED INTERVALS\n";
    reportString += "=======================\n";

    List<LogEventInterval> consolidatedIntervalLog = new List<LogEventInterval>();
    LinkedHashMap<String, List<LogEventInterval>> pagesToIntervalLists = new LinkedHashMap<String, List<LogEventInterval>>();


    for(LogEventInterval interval in intervalLog) {

      /* Get the page */
      String thisPage = interval.pageForInterval;

      /* Convert it to simplified form to add the intervals with pages for races associated with dialogs/inline to the
         same mapping as the regular page */
      if(thisPage.substring(0,4) == "Race") {

        /* We should get "Race #(#)" and if it's extra, we'll just trim it off */
        thisPage = thisPage.padRight(7).substring(0, 7).trim();
      }

      if(pagesToIntervalLists[thisPage] == null)
        pagesToIntervalLists[thisPage] = new List<LogEventInterval>();

      /* Add it to this list */
      pagesToIntervalLists[thisPage].add(interval);
    }

    /* Join all the ones with the same pages */
    pagesToIntervalLists.forEach(
            (String k, List<LogEventInterval> v){
              if(v != null && v.length>0){
                consolidatedIntervalLog.add(new LogEventInterval.join(v, k));
              }
            }
    );

    /* Consolidate these into entire ballot */
    LogEventInterval entireBallotInterval = new LogEventInterval.join(consolidatedIntervalLog, "Entire Ballot");
    consolidatedIntervalLog.add(entireBallotInterval);

    /* Now print all of them */
    for(LogEventInterval interval in consolidatedIntervalLog) {
      reportString += "\n" + interval.summary();
    }

    reportString += "\n\n========\n";
    reportString += "BALLOTS\n";
    reportString += "========\n";

    for(String designation in ballotLog.keys){
      reportString += "\n$designation Ballot:";
      reportString += ballotLog[designation].summary();
    }

    print(reportString);

    return reportString;
  }

}




