'use strict';
(function () {
  const path = require('path');
  const fs = require('fs');

  // Read config from file
  const Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'));

  // Embed elm
  var app = Elm.Main.embed(document.getElementById('window'));

  // Open new pdf when openNewFile msg comes from elm
  app.ports.openNewFile.subscribe(function(resp) {
    var pdfFilePath = resp[0]; // Can be relative path
    var pdfFileName = path.basename(pdfFilePath);
    var pageNum = resp[1];
    var pdfAbsFilePath = path.resolve(path.join(Config.pdf_dir, pdfFileName));
    var pdfUrl = './pdfjs/web/viewer.html?file=' + pdfAbsFilePath + '&page=' + pageNum.toString()
    document.getElementById('pdf-viewer').contentWindow.location.replace(pdfUrl);
    app.ports.pdfUrl.send(pdfUrl);
  });

})()
