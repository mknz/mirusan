'use strict';

// Read config from file
const fs = require('fs');
const path = require('path');
const Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'));

// Copy multiple files synchronously
function copyPdfFilesSync(filePaths) {
  var newPaths = [];
  for (var i = 0; i < filePaths.length; i++) {
    var filePath = path.resolve(filePaths[i]);
    var dstDir = path.resolve(Config.pdf_dir);
    var baseFileName = path.basename(filePath);

    // unify ext to lower case
    if(path.extname(baseFileName) == '.PDF') {
      baseFileName = path.basename(baseFileName, '.PDF') + '.pdf';
    }

    var dstPath = path.join(dstDir, baseFileName);
    var data = fs.readFileSync(filePath);
    fs.writeFile(dstPath, data);
    console.log('Copied to: ' + dstPath);
    newPaths.push(dstPath);
  }
  console.log('Copied all files.');
  return newPaths;
}

// for callback
function addFilesToDB(filePaths) {
  if (process.platform == 'win32') {
    var sub = require('child_process').spawn('./mirusan_search.exe', ['--add-files'].concat(filePaths));
  }
  else if (process.platform == 'linux' || process.platform == 'darwin') {
    var subpy = require('child_process').spawn('python3', ['../search/search.py', '--add-files'].concat(filePaths));
  }
}

require('electron').ipcRenderer.on('pdf-extract-request-background', (event, message) => {
  var pdfPaths = message.pdfPaths; // can be non-absolute path
  var pdfAbsPaths = [];
  for (var i=0; i < pdfPaths.length; i++) {
    pdfAbsPaths.push(path.resolve(pdfPaths[i]));
  }
  var newPdfPaths = copyPdfFilesSync(pdfAbsPaths); // NOTE: blocking operation
  // Extract text, add to DB
  pdf2txt.pdfFilesTotxt(newPdfPaths, path.resolve(Config.txt_dir), addFilesToDB);
})
