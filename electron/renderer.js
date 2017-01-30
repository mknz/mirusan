'use strict';
const path = require('path');

// Adjust inline frame size with window
function resizeFrame() {
  const margin = 50; // Influenced by header's height
  var windowHeight = document.documentElement.clientHeight;
  var elem = document.getElementById('pdf-viewer-container');
  elem.style.height = windowHeight - margin + 'px';
  var elem = document.getElementById('sidebar-container');
  elem.style.height = windowHeight - margin + 'px';
}

// init elem sizes
// workaround: wait until container elements appear
setTimeout(resizeFrame, 100);

window.addEventListener('resize', function(e) {
  resizeFrame()
}, false);

// Embed elm
var app = Elm.Main.embed(document.getElementById('window'));

// Open new pdf when openNewFile msg comes from elm
app.ports.openNewFile.subscribe(function(resp) {
  var pdfFilePath = path.resolve(path.join('../data/pdf', resp[0]));
  var pageNum = resp[1];
  document.getElementById('pdf-viewer').contentWindow.location.replace('./pdfjs/web/viewer.html?file=' + pdfFilePath + '&page=' + pageNum.toString());
});

// Get document paths to add DB by dialog, send them back to elm
var elem = document.getElementById('getFilesToAddDB');
elem.addEventListener('change', function(e) {
  var files = e.target.files;
  var filePaths = [];
  for (var i = 0 ; i < files.length ; i++ )
  {
    filePaths.push(files[i].path);
  }
  app.ports.filesToAddDB.send(filePaths);
}, false);

// Invoke file open dialog.
app.ports.getFilesToAddDB.subscribe(function() {
  var elem = document.getElementById('getFilesToAddDB');
  elem.click();
});

