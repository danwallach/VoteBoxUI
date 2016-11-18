import 'dart:io';
import 'dart:convert' show JSON;
import 'dart:async';
import 'dart:core';

/* A simple web server that responds to **ALL** GET requests by returning
 * the contents of data.json file, and responds to ALL **POST** requests
 * by overwriting the contents of the data.json file
 * 
 * Browse to it using http://localhost:8080  
 * 
 * Provides CORS headers, so can be accessed from any other page
 * see https://github.com/chrisbu/dartlang_json_webservice_article_code
 *
 * DO NOT USE THIS SERVER FOR ANY ACTUAL ELECTIONS! IT IS COMPLETELY UNSECURED!
 */

final String HOST = r"127.0.0.1"; // eg: localhost
final int PORT = 8888;
final String DATA_FILE = "data.json";
String justWritten = "";
String toWrite;

main() async {

  Process.start(r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
      [r'--profile-directory=Default', r'--app-id=jinjkkheinoeggackbhoiggmoegackko', r'%USERPROFILE%\Desktop\election.xml'],
      runInShell:true);

  HttpServer.bind(HOST, PORT).then((server) {
    server.listen((HttpRequest request) {
      switch (request.method) {
        case "GET": 
          handleGet(request);
          break;
        case "POST": 
          handlePost(request);

          if(justWritten != "results") {

            if (Platform.operatingSystem != 'macos') {
              print('Your operating system is ${Platform.operatingSystem}. Printing for Windows... ');
              runScript(['printStylizedBallotUsingFoxitFromJSON.dart']);
            } else {
              print('Your operating system is ${Platform.operatingSystem}. Printing for Mac... ');
              runScript(['printStylizedBallotUsingLPRFromJSON.dart']);
            }
            print("Printing complete!");

          } else {

            print("Emailing results...");
            runScript(['emailResults.dart', toWrite]);
          }

          justWritten = "";

          break;
        case "OPTIONS": 
          handleOptions(request);
          break;
        default: defaultHandler(request);
      }
    }, 
    onError: printError);
    
    print("Listening for GET and POST on http://$HOST:$PORT");
  },
  onError: printError);

}

/**
 * Handle GET requests by reading the contents of data.json
 * and returning it to the client
 */
void handleGet(HttpRequest req) {
  HttpResponse res = req.response;
  print("${req.method}: ${req.uri.path}");
  addCorsHeaders(res);
  
  var file = new File(DATA_FILE);
  if (file.existsSync()) {
    res.headers.add(HttpHeaders.CONTENT_TYPE, "application/json");
    file.readAsBytes().asStream().pipe(res); // automatically close output stream
  }
  else {
    var err = "Could not find file: $DATA_FILE";
    res.addString(err);
    res.close();  
  }
  
}

/**
 * Handle POST requests by overwriting the contents of data.json
 * Return the same set of data back to the client.
 */
void handlePost(HttpRequest req) {
  HttpResponse res = req.response;
  print("${req.method}: ${req.uri.path}");

  toWrite = DATA_FILE;

  if(req.uri.path == "/report") {
  	DateTime current = new DateTime.now();
    /* Replace all ':' with essentially identical unicode character */
    toWrite = "results/results${current.toString().replaceAll(new RegExp(r':'),'\uA789')}.txt";
    justWritten = "results";
  } else if(req.uri.path == "/finish") {
    /* Wait for one second to make sure UI has closed */
    sleep(new Duration(seconds: 1));
  	exit(0);
  } else {
    justWritten = "";
  }


  addCorsHeaders(res);
  
  req.listen((List<int> buffer) {

    /* Write to results/results{timestamp}.txt or data.json*/
    File file = new File(toWrite);
    file.createSync(recursive: true);
    IOSink ioSink = file.openWrite(); // save the data to the file
    ioSink.add(buffer);
    ioSink.close();

  });
}
/**
  Runs another dart script (the file is in the same directory) that will perform the following actions for printing:
    1. Read in the saved JSON file,
    2. Convert the data into a string that is valid, stylized HTML
    3. Write that new string to a .html file
    4. Use prince to convert the new .html into a rendered pdf (with the barcode!)
    5. Use lpr to (silently!) print out that new pdf
*/
void runScript(List<String> arguments) {
  print(arguments);
  print(Directory.current.path);
    try {
    Process.run('dart', arguments, workingDirectory: Directory.current.path, runInShell:false)
            .then((process) =>  print(process.stdout));
  } catch (exception, StackTrace) {
    print('Uh oh! Problem running our script!');
    print(exception);
    print(StackTrace);
  }
}
/**
 * Add Cross-site headers to enable accessing this server from pages
 * not served by this server
 * 
 * See: http://www.html5rocks.com/en/tutorials/cors/ 
 * and http://enable-cors.org/server.html
 */
void addCorsHeaders(HttpResponse res) {
  res.headers.add("Access-Control-Allow-Origin", "*");
  res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
}

void handleOptions(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  print("${req.method}: ${req.uri.path}");
  res.statusCode = HttpStatus.NO_CONTENT;
  res.close();
}

void defaultHandler(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  res.statusCode = HttpStatus.NOT_FOUND;
  res.addString("Not found: ${req.method}, ${req.uri.path}");
  res.close();
}

void printError(error) => print(error);