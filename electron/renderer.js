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
    var pdfFilePath = resp[0]; // Can be relative path
    var pdfFileName = path.basename(pdfFilePath);
    var pageNum = resp[1];
    var pdfAbsFilePath = path.resolve(path.join(Config.pdf_dir, pdfFileName));
    document.getElementById('pdf-viewer').contentWindow.location.replace('./pdfjs/web/viewer.html?file=' + pdfAbsFilePath + '&page=' + pageNum.toString());
  });

})()
