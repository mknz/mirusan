'use strict';
const path = require('path');

// Convert text file name, return pdf filename and page
// "FILE_pN.txt" -> {filePath: "FILE.pdf", pageNum: N}
function getPDFfileName(textFileName) {
  var fileName = textFileName.split('_').slice(0, -1).join('_') + '.pdf';
  var pageNum = parseInt(textFileName.split('_').pop().split('.')[0].slice(1));
  var filePath = path.resolve(path.join('../data/pdf', fileName));
  console.log(filePath);
    return {filePath: path.resolve(path.join('../data/pdf', fileName)), pageNum: pageNum};
}

// Adjust inline frame size with window
function resizeFrame() {
  var windowHeight = document.documentElement.clientHeight;
  var mainHeight = document.getElementById('main-container').clientHeight;
  if (windowHeight > mainHeight) {
    var pdfHeight = windowHeight;
  } else {
    var pdfHeight = mainHeight;
  }
  var elem = document.getElementById('pdf-viewer-container');
  elem.style.height = pdfHeight + 'px';
  var elem = document.getElementById('pdf-viewer');
  elem.style.height = pdfHeight + 'px';
}
resizeFrame();

// Embed elm
var app = Elm.Main.embed(document.getElementById('search'));

// Open new pdf when openNewFile msg comes from elm
app.ports.openNewFile.subscribe(function(fileName) {
  var pdfFilePath = getPDFfileName(fileName).filePath;
  var pageNum = getPDFfileName(fileName).pageNum;
  document.getElementById('pdf-viewer').contentWindow.location.replace('./pdfjs/web/viewer.html?file=' + pdfFilePath + '&page=' + pageNum.toString());
  resizeFrame();
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

