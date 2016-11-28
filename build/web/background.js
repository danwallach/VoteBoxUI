/**
 * Listens for the app launching, then creates the window.
 *
 * @see http://developer.chrome.com/apps/app.runtime.html
 * @see http://developer.chrome.com/apps/app.window.html
 */
chrome.app.runtime.onLaunched.addListener(function(launchData, launchData1) {

  chrome.app.window.create(
    'VoteBoxUI-htmlSource.html',

    {
      id: 'mainWindow',
      state: "fullscreen"
    },

    function(createdWindow) {

      chrome.runtime.getPackageDirectoryEntry(
          function(root) {
        
          root.getFile("novemberballot.xml", {}, function(fileEntry) {
          fileEntry.file(function(file) {
            var reader = new FileReader();
            var XML;
            reader.onloadend = function(e) {
              XML = reader.result;
              chrome.storage.local.set({'XML': XML});
            };
            reader.readAsText(file);
          }, 
          function(){
            console.log("Error reading XML file");
          });
        }, 

        function(){
            console.log("Error reading XML file");
          });
      });

      chrome.runtime.getPackageDirectoryEntry(
          function(root1) {
        
          root1.getFile("sample.xml", {}, function(fileEntry1) {
          fileEntry1.file(function(file1) {
            var reader1 = new FileReader();
            var XML2;
            reader1.onloadend = function(e) {
              XML2 = reader1.result;
              chrome.storage.local.set({'XML2': XML2});
            };
            reader.readAsText(file1);
          }, 
          function(){
            console.log("Error reading XML file");
          });
        }, 

        function(){
            console.log("Error reading XML file");
          });
      });

      //createdWindow.fullscreen();
      //createdWindow.onkeydown(function(e) { if (e.keyCode == 27 /* ESC */) { e.preventDefault(); }});
      //createdWindow.onkeyup(function(e) { if (e.keyCode == 27 /* ESC */) { e.preventDefault(); }});
    }
  );



});


