'use strict';
(function () {
  const path = require('path');
  const fs = require('fs');

  // Read config from file
  const Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'));

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
    var pdfFileName = resp[0];
    var pageNum = resp[1];
    var pdfFilePath = path.join(Config.pdf_dir, pdfFileName);
    document.getElementById('pdf-viewer').contentWindow.location.replace('./pdfjs/web/viewer.html?file=' + pdfFilePath + '&page=' + pageNum.toString());
  });

  // Get document paths to add DB by dialog
  var elem = document.getElementById('getFilesToAddDB');
  elem.addEventListener('change', function(e) {
    var files = e.target.files;
    var filePaths = [];
    // Check all files are pdf
    for (var i = 0 ; i < files.length; i++ )
    {
      var filePath = files[i].path;
      var fileName = path.basename(filePath);
      if (['pdf', 'PDF'].indexOf(fileName.split('.').pop()) >= 0) {
          filePaths.push(filePath);
      }
    }
    if (files.length != filePaths.length) {
      alert('Please select only pdf files.');
      return;
    }

    // Copy pdf files to data dir
    var pdfPaths = [];
    for (var i = 0; i < filePaths.length; i++) {
      var filePath = filePaths[i];
      var dstPath = path.join(Config.pdf_dir, path.basename(filePath));
      console.log('Copy to: ' + dstPath);
      fs.createReadStream(filePath).pipe(fs.createWriteStream(dstPath));
      pdfPaths.push(dstPath);
    }

    // Extract text from pdf, call elm when finished
    pdf2txt.pdfFilesTotxt(pdfPaths, Config.txt_dir, app.ports.filesToAddDB.send)

  }, false);

  // Invoke file open dialog.
  app.ports.getFilesToAddDB.subscribe(function() {
    var elem = document.getElementById('getFilesToAddDB');
    elem.click();
  });
})()
