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
    // abs path
    var pdfFilePath = path.resolve(path.join(Config.pdf_dir, pdfFileName));
    console.log(pdfFilePath);
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
      var filePath = path.resolve(filePaths[i]);
      var dstPath = path.join(Config.pdf_dir, path.basename(filePath));
      pdfPaths.push(path.resolve(dstPath));
      fs.readFile(filePath, (err, data) => {
        if (err) throw err;
        fs.writeFile(dstPath, data, (err) => {
          if (err) throw err;
          console.log('Copy complete: ' + dstPath);
          pdf2txt.pdfFilesTotxt([filePath], path.resolve(Config.txt_dir), app.ports.filesToAddDB.send);
        })
      })
    }
  }, false);

  // Invoke file open dialog.
  app.ports.getFilesToAddDB.subscribe(function() {
    var elem = document.getElementById('getFilesToAddDB');
    elem.click();
  });
})()
