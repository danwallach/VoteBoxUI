import 'dart:io';
import 'dart:convert' show JSON;
import 'dart:async';

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
final String DATA_FILE = r"C:\Users\seclab2\Desktop\nonSecuredWebServer\data.json";
String justWritten = "";
int i = 1;
String wd = "./";

void main() {

  HttpServer.bind(HOST, PORT).then((server) {
    server.listen((HttpRequest request) {
      switch (request.method) {
        case "GET": 
          handleGet(request);
          break;
        case "POST": 
          handlePost(request);

          if(justWritten != "results") {
            print('NOW TO PRINT!');


            if (Platform.operatingSystem != 'macos') {
              print('Printing for windows! Your operating system is ${Platform.operatingSystem}');
              runScript(['printStylizedBallotUsingFoxitFromJSON.dart']);
            } else {
              print('Printing for mac! Your operating system is ${Platform.operatingSystem}');
              runScript(['printStylizedBallotUsingLPRFromJSON.dart']);
            }
            print('FINISHED TRYING TO PRINT');
            print('IF NOTHING PRINTED OUT, DOUBLE CHECK THAT THE PATH TO THE PRINTER IS CORRECT');

          } else {

            print('Your operating system is ${Platform.operatingSystem}');

            if (Platform.operatingSystem != 'macos') {
              wd=r"C:\Users\seclab2\Desktop\nonSecuredWebServer";
            }

            runScript(['emailResults.dart', 'results${i}.txt']);
            i++;
          }

          justWritten = "";
          //exit(0);
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

  String toWrite = DATA_FILE;

  if(req.uri.path != "/") {
    //toWrite = r"C:\Users\seclab2\Desktop\nonSecuredWebServer\results.txt";
    toWrite = "results${i}.txt";
    justWritten = "results";
  }

  addCorsHeaders(res);
  
  req.listen((List<int> buffer) {

    /* Write to results#.txt */
    File file = new File(toWrite);
    IOSink ioSink = file.openWrite(); // save the data to the file
    ioSink.add(buffer);
    ioSink.close();

    /* Write to results.txt */
    file = new File("results.txt");
    ioSink = file.openWrite(); // save the data to the file
    ioSink.add(buffer);
    ioSink.close();

    // return the same results back to the client
    res.add(buffer);
    res.close();
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
Future runScript(List<String> arguments) async {
  try {
    return Process.run('dart', arguments, workingDirectory: wd, runInShell:false).then((ProcessResult p) => print("${p.stdout}"));;
  } catch (exception, StackTrace) {
    print('Uh oh! Problem running our script!');
    print(exception);
    print(StackTrace);
    return new Future.error("Script error");
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
