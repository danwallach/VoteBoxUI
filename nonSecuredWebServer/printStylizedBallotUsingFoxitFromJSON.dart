import 'dart:async';
import 'dart:io';
import 'dart:convert' show JSON;
import 'dart:core'; 
main() async {

  String inputFileName = r'C:\Users\seclab2\Desktop\nonSecuredWebServer\data.json';
  String outputHTMLFileName = r'C:\Users\seclab2\Desktop\nonSecuredWebServer\printThis.html';
  String outputPDFFileName = r'C:\Users\seclab2\Desktop\nonSecuredWebServer\printThis.pdf';
  String outputString;

  //MAKE SURE THIS IS CORRECT IF SOMETHING FAILS TO PRINT!!!
  String printerName = r'Hewlett-Packard HP LaserJet P2055dn';

  print('Test');
  print('Starting script at ... ${(await Process.run('cd',[], runInShell: true)).stdout}');

  new File(inputFileName).readAsString().then((String contents) {
    print(contents);
    print('now converted:');
    print(JSON.decode(contents));
    print('now generating HTML');

    try {
      outputString = (generatePrintableHTML(JSON.decode(contents)));
    } catch (exception, stackTrace) {
      print (exception);
      print (stackTrace); 
      return;
    }

    print ('This is the outputString ->');
    print (outputString);

    final String fileName = outputHTMLFileName;
    File outputHTMLFile = new File (fileName);
    //Create the output HTML file
    print ('Creating the .html file for our stylized printout');
    try {
      if (outputHTMLFile.existsSync()) {
        outputHTMLFile.deleteSync();
      }
      outputHTMLFile.createSync();
    } catch (exception, stackTrace) {
      print ('UH OH! Failure deleting/creating the output HTML File!');
      print (exception);
      print (stackTrace);
      return;
    }

    //Write the output String to our newly created file
    print('Writing to the .html file');
    try {
      outputHTMLFile.writeAsStringSync(outputString);
    } catch (exception, StackTrace) {
      print('Uh oh! Failed to write to ${outputHTMLFileName}');
      print(exception);
      print(stackTrace);
      return;
    }


    //Convert the HTML file to a pdf file
    //Turns out there isn't an easier way to do multiple synchrous processes that these .then lambdas -_-
    print ('Converting the .html file to the stylized pdf file');
    Process.run(r'C:\Program Files (x86)\Prince\Engine\bin\prince.exe', [outputHTMLFileName, '-o', outputPDFFileName], runInShell:false)
      .then ((ProcessResult results) {
        print(results.stdout);

        print ('(Hopefully) Finished Conversion of HTML file to PDF');
        print ('Now to try to print out the file');



        //USED IN MAC - LPR DIDNT WORK FOR ME IN WINDOWS!  Process.run('lpr', [outputPDFFileName], runInShell:true)
        Process.run(r'C:\Program Files (x86)\Foxit Software\Foxit Reader\FoxitReader.exe', [r'/t', outputPDFFileName, printerName], runInShell:false)
          .then ((ProcessResult results){
            print(results.stdout);
            print ('SHOULD BE DONE NOW! If this has not sent something to the print queue yet, something is wrong');
          }).catchError((c) {
            print ('There was this type of (c) error -> ${c.runtimeType}');
            print ('trying to print the error directly -> ${c}');
            print ('This error came from the innermost .catchError from running the lpr print command');
          });
      }).catchError((b) {
        print ('There was this type of (b) error -> ${b.runtimeType}');
        print ('trying to print the error directly -> ${b}');
        print ('This error came from the middle .catchError from running Prince');
      });
  }).catchError((a) {
    //Errors that get passed up from lower down in the chain (closes up the original opened File)
    print ('There was this type of (a) error -> ${a.runtimeType}');
    print ('trying to print the error directly -> ${a}');
    print ('This error came from the outermost .catchError in the main() of this file');
  });
}



/**
 * This function returns the entire html page for the ballot print (AKA 'Record of Voter
 *  Intent'), INCLUDING The CSS <style> block (see the example file for any questions)
 *
 * Inputs:
 *      This code uses the global 'races' array but doesn't actually take in any inputs (as of now)
 *      If we refactor this code to get rid of the constant use of  globals then this will need to
 *      take races as an input.
 *
 * Outputs:
 *      A string that holds the entire html page for the ballot print (AKA 'Re
 *
 **/
String  generatePrintableHTML(List<Map<String, String>> inputData) {
    var outputBuffer = new StringBuffer();

    //initial setup F
    outputBuffer.write('<!DOCTYPE html>\n');
    outputBuffer.write('<html>\n');
    outputBuffer.write('<head>\n');
    outputBuffer.write('<style>\n');

    //CSS overall font
    outputBuffer.write('html * { font-family: "Avenir Next" !important; color: black;}\n');

    //CSS classes, taken directly (but formatted differently to save space) from the example HTML/CSS printout 6/18/15
    //TODO - make this more legible
    
    outputBuffer.writeAll(['hr.divideRace { /* Formatting for the black horizontal line that divides up the races */',
            ' display: block; font-size: 13.5pt; margin-top: -1.5pt; margin-left: 0pt; margin-bottom: 10pt;',
            ' margin-right: 0pt; font-weight: bolder; }\n',
            'h1 { /*Upper left header ("Official Ballot")*/ display: inline; font-size: 13.5pt; margin-top: 0pt;',
            ' margin-left: 36pt; margin-bottom: 0pt; margin-right: 0pt; font-weight: bold; } \n',
            'h2 { /*Upper rightt header ("PLACE THIS IN BALLOT BOX")*/ display: inline;',
            ' text-align: right; font-size: 17.3pt; margin-top: 0pt; margin-right: 36pt; margin-left: 100pt;',
            ' margin-bottom: 0pt; font-weight: bold; } \n',
            'divDate { /*Date, just underneath the first (upper left)',
            ' header*/ display:block; font-size: 10.1pt; margin-top: -5pt; margin-left: 36pt; margin-bottom: 0pt;',
            ' margin-right: 36pt; font-weight: normal; } \n', 
            ' divLocation { /*Location, just underneath the date*/',
            ' display: block; font-size: 10.1pt; margin-top: -2.5pt; margin-left: 36pt; margin-bottom: 19pt;',
            ' margin-right: 36pt; font-weight: normal; }  \n', 
            'div.electionOrProposition { /*The name of each election */',
            ' display:block; font-size: 11pt; margin-top:0pt; margin-left:0pt; margin-bottom: 1.5pt; margin-right:0pt; ',
            ' font-weight: bold } \n',  
            'div.namePlusAND { /* ONLY used for the first person of two total */ display:block;',
            ' font-size: 10.5pt; margin-top:0pt; margin-left:0pt; margin-bottom: -3pt; margin-right:5pt; font-weight:',
            ' normal; }  div.onlyOrSecondPerson { /* Used for one person total, or the second of two.',
            ' THIS ONE IS SPECIAL - it relies on using the width field to work with .party!! */ display: inline-block;',
            ' font-size: 10.5pt; margin-top:0pt; margin-left:0pt; margin-bottom: 0pt; margin-right:0pt; font-weight:',
            ' normal; width: 82%; }\n', 
            'div.namePlusAND {/* ONLY used for the first person of two total */ display:block;',
            ' font-size: 10.5pt; margin-top:0pt; margin-left:0pt; margin-bottom: -3pt; margin-right:5pt; font-weight: normal; } \n',
            'div.onlyOrSecondPerson { /* Used for one person total, or the second of two. THIS ONE IS SPECIAL - it relies',
            ' on using the width field to work with .party!! */ display: inline-block; font-size: 10.5pt; margin-top:0pt;',
            ' margin-left:0pt; margin-bottom: 0pt; margin-right:0pt; font-weight: normal; width: 82%; }\n',  
            'div.party { /* SPECIAL - only used for sticking party on the same line as the (second, if a team) person being voted for */',
            ' display: inline-block; font-size: 10.75pt; text-align: right; font-weight:bold; width: 8%; }\n', 
            'div.noSelection_outer { /* SPECIAL - only used for highlighting the special "YOU DID NOT SELECT ANYTHING" message */ display: block;',
            ' background-color: #D6D7D8; } \n',  
            'div.noSelection_inner {/* SPECIAL - only used for the font and positioning of',
            ' the special "YOU DID NOT SELECT ANYTHING" message */ font-size: 10.75pt; margin-top:0pt; margin-left:6pt;',
            ' margin-bottom: 0pt; margin-right:0pt; font-weight: bold; }\n', 
            'divLeftSide {/*SPECIAL - Contains the left side of the',
            ' page*/ float: left; width: 190pt; padding-left: 36pt; line-height:15pt; }\n divRightSide {/*SPECIAL -',
            ' Contains the right side of the page*/ float: right; width: 190pt; margin-right: 36pt; line-height:15.5pt; }']);

    outputBuffer.write('</style>\n');
    outputBuffer.write('</head>\n');


    //actual data
    outputBuffer.write('<body>\n');

    //TODO - format this better (leaving as is for now since it doesn't affect output. See exapmle CSS page for details)
    outputBuffer.write('<h1>Official Ballot</h1> <h2>PLACE THIS IN BALLOT BOX</h2>\n');
    outputBuffer.write('<divDate>November 8, 2016, General Election</divDate> <divLocation>Harris County, Texas Precint 101A</divLocation>\n');

    //now formatting the races on the left side of the printout page
    outputBuffer.write('<divLeftSide>\n');

    //first of the two main for-loop where we auto-generate stuff
    //each "block" is one race or proposition; the LEFT is because these blocks are on the left side of the printout page
    //TODO - Check this setup is ok
    //propositions are shorter text so we do one more block on the left side
    //(just in case you haven't seen it before, in dart ~/ means you're flooring after the division!)
    for(int blockNumberLEFT = 0; blockNumberLEFT < inputData.length ~/ 2; blockNumberLEFT++) { //TODO - check for rounding errors.
        // Each iteration focueses on one particular race or proposition
        String nextLeftSideBlock =  handleOneBlockHTML(blockNumberLEFT, inputData[blockNumberLEFT]);
        outputBuffer.write(nextLeftSideBlock);
    }

    outputBuffer.write('</divLeftSide>\n');
    //now the same thing for the races on the right side of the printout page
    outputBuffer.write('<divRightSide>\n');

    //second of the main for-loops where we auto-generate stuff
    //the RIGHT at the end is because these blocks are on the right side of the printout
    for(int blockNumberRIGHT = inputData.length ~/ 2; blockNumberRIGHT < inputData.length; blockNumberRIGHT++) { //TODO - again, check for rounding errors
        // Each iteration focueses on one particular race or proposition
        String nextRightSideBlock = handleOneBlockHTML(blockNumberRIGHT, inputData[blockNumberRIGHT]);
        outputBuffer.write(nextRightSideBlock);
    }
    outputBuffer.write('</divRightSide>\n');

    //TODO - what's this line doing?
    //outputBuffer.write(document.getElementById('Results').value);

    //TODO - change the image to be better!
    outputBuffer.write('<img src="fakeBarcode.jpg" alt="BARCODE GOES HERE" style="width:350px;height:35px;">');

    //now just close it up
    outputBuffer.write('</body>\n');
    outputBuffer.write('</html>\n');
    return outputBuffer.toString();
}
/**
 * The main function that handles each individual "block" of HTML for the printout of hte ballot
 * I am defining one "block" to be either one race or proposition 
 *
 * This function will be called once for each iteration of the for loops in the main HTML generating function
 *
 *  ***TODO - Right now, we rely on hardcoding in selections the helper functions for dealing with multi-person races 
 *            using the number of the race or proposition (what I later call the "block number") since the races
 *            for this research is remaining fixed (for the next few months at least) 
 * 
 *            Eventually, we'll need to have a way to determine up here what type of block we're dealing with,
 *            and call one of the helper functions based on this intelligent selection, *            all blocks the same way.
 * 
 *  STYLE GUIDE for CSS:
 *
 *     Excepting what is listed at the bottom of this:
 *     Each piece will have a 1 line description
 *     All colons will have one space following them
 *     There will be no spaces before the semicolons
 *     Depending on the font weight, you may need to change the size slightly
 *     Prefer using top margins for spacing when possible
 *
 *     The order shall go:
 *     description
 *     display
 *     fontsize
 *     top margin (basically, go counterclockwise)
 *     left margin
 *     bottom margin
 *     right margin
 *     bolding weight of font
 *
 *
 *     EXCEPTIONS:
 *        1.xdivLeftSide and divRightSide: 2 floating divs I use to split up the left and right side
 *
 *        2. Div.party and div.onlyOrSecondPerson: Getting the party name inline to the right of candidate names
 */
String handleOneBlockHTML(blockNumber, inputRaceMap) {
    String identifier = inputRaceMap['IDENTIFIER']; 
    String race = inputRaceMap['RACE'];
    String group = inputRaceMap['GROUP'];
    bool twoPersonSelection = false; //for now, just a flag for presidential elections (two people on ticket)

    //TODO - see docstring; eventually will figure this out from other information, instead of hardcoding it like this
    //WARNING!!! - if you take out the error checking inside this, you will need to change this to an && for proper behavior!
    if (blockNumber == 0 || race == "President and Vice President") {
        twoPersonSelection = true;

        //true&&true==true, false&&false==false, and trueXORtrue is an error
        //unfortunately there is no quick XOR in javascript, so I made the earlier line an OR and then checked if either were false
        if (blockNumber != 0 || race != "President and Vice President") {
            print("\nAs of now, only the Presidential election can have two candidates, and it must be the 0th election\n");
            String errorString = "ERROR IN TWO PERSON SELECTION!!!!!! race is not pres and vicepres, and blockNumber is 0; one of these is wrong!";
            return errorString;
        }
    }

    //determine who the person voted for, if any
    //inputArray[i] gets a map for the ith race with 3 fields: 'RACE', 'IDENTIFIER', and 'GROUP'
   


    //this means the voter skipped this one, and didn't make a selection
    if (identifier == '') {
        return generateBlock_NOSELECTION(blockNumber, race);
    } else {
        //double check they DID make a selection
        assert (identifier != null);
        assert (identifier != '');
        //this means the voter DID make a selection 
        //TODO - eventually this probably need to support more types of blocks, and handle more two-person tickets than just Presidential
        //TODO -   (contd) which we long term shouldn't assume will always be the very first race voted on in the election
        if (race == "President and Vice President") {
        	//TODO - when more than just 0th election as pres/vicepres is supported, this will be taken out!
        	assert(blockNumber == 0);

        	//THIS COULD BE A SECURITY VULNERABILITY if it was used outside the lab for more than just voting psychology research
            var helperArray = identifier.split(" and ");

          	//Checking that this were in fact two names in the identifier
            assert (helperArray.length == 2);
            assert (helperArray[0] != '');
            assert (helperArray[1] != '');

            print("\n\n\n\n testing - these should be two names!-> ");
            print(helperArray[0]);
            print('\nand\n');
            print(helperArray[1]); 
            print("from this array -> ");
            print (helperArray);
            //Takes as inputs the blocknumber, candidate 1, candidate 2, the party, and the name of the race
            return generateBlock_Race_TwoPersonSelection(blockNumber, helperArray[0], helperArray[1], group, race);
        } else {
            //TODO - special case for propositions
            //Anything that's not presidential election 
            return (generateBlock_Race_OnePersonSelection(blockNumber, identifier, group, race));
        }
    }

}

/*************************************
 *** BEGIN BLOCK GENERATION FUNCTIONS 
 *
 * These are the various functions that generate the actual text of each of the blocks
 *
 * Name style:
 *      generateBlock_<either 'Race' or Proposition>_<additional specifications>
 *  
 * inputs: blockNumber, chosenCandidate, chosenCandidateParty
 * 
 * Each should follow the same general format (excepting the NOSELECTION function), and will return the text as a string
 * 
 * TODO - propositions
 */

/*
 * Standard sort of election race. with one person on each ticket
 *
 * TODO - don't use block number to determine the race like this - change it to take in an inputted
 * string like with the candidate and part
 */
String generateBlock_Race_OnePersonSelection (blockNumber, chosenCandidate, chosenCandidateParty, nameOfRace) {

    //TODO - assuming the syntax used in the twopersonselection works, condense this similarly
    StringBuffer constructingBlock = new StringBuffer();

    //stick in the name of the election
    constructingBlock.write('<div class="electionOrProposition">' + nameOfRace +  '</div> ');

    //stick in the selected candidate's name
    constructingBlock.write('<div class="onlyOrSecondPerson">');
    constructingBlock.write(chosenCandidate);
    constructingBlock.write('</div> ');

    //stick in the party of the selected candidate
    constructingBlock.write('<div class="party">');
    constructingBlock.write(chosenCandidateParty);
    constructingBlock.write('</div>');
    constructingBlock.write('<hr class ="divideRace">');

    return constructingBlock.toString();
}


/*
 * Standard sort of election race, but with TWO people running together on each ticket
 *
 * For the demo, this is only for the presidential election'
 * 
 * TODO - eventually this will need to handle more than just the presidential election
 
 * TODO - don't use block number to determine the race like this - change it to take in an inputted
 * string like with the candidate and part
 */
String generateBlock_Race_TwoPersonSelection (blockNumber, chosenCandidate0, chosenCandidate1, chosenCandidateParty, nameOfRace){
    
    StringBuffer constructingBlock = new StringBuffer();
    
    if (blockNumber != 0) {
        //TODO - what sort of exception or error?
        print("Uh oh! Something other than the 0th race in the two person selection! Current blockNumber is ${blockNumber}");
    }
    if (nameOfRace != "President and Vice President") {
        //TODO - change the string above to the correct one
        print("Uh oh! Something other than the Presidential Election in the two person selection! Current nameOfRace is ${nameOfRace}");
    }

    print("\nThe things we have are blockNumber, chosenCandidate0, chosenCandidate1, chosenCandidateParty, and nameOfRace ->  ${blockNumber}, ${chosenCandidate0}, ${chosenCandidate1}, + ${chosenCandidateParty}, ${nameOfRace} \n");
    
    //stick in the name of the election
    constructingBlock.write('<div class="electionOrProposition">' + nameOfRace +  '</div>');

    // stick in the first person's name, as well as the "And"
    constructingBlock.write('<div class="namePlusAND"> ' +  chosenCandidate0 + 'and </div>');

    //stick in the second person's name/
    constructingBlock.write('<div class="onlyOrSecondPerson">' + chosenCandidate1 + '</div>');

    //stick in the party of the selected candidate
    constructingBlock.write('<div class="party">' + chosenCandidateParty + '</div>');
    constructingBlock.write('<hr class ="divideRace">');

    return constructingBlock.toString();
}

String generateBlock_NOSELECTION(blockNumber, nameOfRace) {
    //TODO - need to divide this so that we get the extra line for unselected two party tickets without relying on the block number like this
    StringBuffer constructingBlock = new StringBuffer();
    constructingBlock.write('<div class="electionOrProposition"> ${nameOfRace}  </div>');

    if (blockNumber == 0) { //TODO - later on, when it's more general purpose, this quick hack won't work
        constructingBlock.write('<br>\n'); //Since unselected two-person tickets need an extra space in there
    }
    constructingBlock.write('<div class="noSelection_outer"><div class="noSelection_inner">YOU DID NOT SELECT ANYTHING</div></div>');
    constructingBlock.write('<hr class ="divideRace">');

    return constructingBlock.toString();
}

/*** END BLOCK GENERATION FUNCTIONS
 ***********************************/

