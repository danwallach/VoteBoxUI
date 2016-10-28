/**
 * Listens for the app launching, then creates the window.
 *
 * @see http://developer.chrome.com/apps/app.runtime.html
 * @see http://developer.chrome.com/apps/app.window.html
 */
chrome.app.runtime.onLaunched.addListener(function(launchData) {

  chrome.app.window.create(
    'VoteBoxUI-htmlSource.html',

    {
      id: 'mainWindow',
      state: "fullscreen"
    },

    function(createdWindow) {

        console.log(launchData.items[0]);
      if(launchData.items) {
        launchData.items[0].entry.file(
  
          function(result) {
  
            var reader = new FileReader();
            var XML;
  
            reader.onloadend = function(){
              XML = reader.result;
              chrome.storage.local.set({'XML': XML});
            };
  
            reader.readAsText(result);
  
          },
  
          function(){
            console.log("Error reading XML file");
          }
  
        );
      }
      else {
        console.log("No file was detected.");
      }

      //createdWindow.fullscreen();
      //createdWindow.onkeydown(function(e) { if (e.keyCode == 27 /* ESC */) { e.preventDefault(); }});
      //createdWindow.onkeyup(function(e) { if (e.keyCode == 27 /* ESC */) { e.preventDefault(); }});
    }
  );

});



