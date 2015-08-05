/**
 * Listens for the app launching, then creates the window.
 *
 * @see http://developer.chrome.com/apps/app.runtime.html
 * @see http://developer.chrome.com/apps/app.window.html
 */
chrome.app.runtime.onLaunched.addListener(function(launchData) {

  document.createElement("XMLFile");
  document.XMLFile = launchData.items[0].entry;

  chrome.app.window.create(
    'VoteBoxUI-htmlSource.html',
    {
      id: 'mainWindow',
      bounds: {width: 1600, height: 800 }
    }
  );
});
