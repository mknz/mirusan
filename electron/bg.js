'use strict';

// Read config from file
const fs = require('fs');
const path = require('path');
const Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'));

// Copy multiple files synchronously
function copyFilesSync(filePaths) {
  for (var i = 0; i < filePaths.length; i++) {
    var filePath = path.resolve(filePaths[i]);
    var dstPath = path.join(path.resolve(Config.pdf_dir), path.basename(filePath));
    var data = fs.readFileSync(filePath);
    fs.writeFile(dstPath, data);
    console.log('Copied to: ' + dstPath);
  }
  console.log('Copied all files.');
}

// for callback
function addFilesToDB(txtFilePaths) {
  if (process.platform == 'win32') {
    var sub = require('child_process').spawn('./mirusan_search.exe', ['--add-files'].concat(txtFilePaths));
  }
  else if (process.platform == 'linux') {
    var subpy = require('child_process').spawn('python3', ['../search/search.py', '--add-files'].concat(txtFilePaths));
  }
}

require('electron').ipcRenderer.on('pdf-extract-request-background', (event, message) => {
  var pdfPaths = message.pdfPaths; // can be non-absolute path
  var pdfAbsPaths = [];
  for (var i=0; i < pdfPaths.length; i++) {
    pdfAbsPaths.push(path.resolve(pdfPaths[i]));
  }
  copyFilesSync(pdfAbsPaths); // NOTE: blocking operation
  pdf2txt.pdfFilesTotxt(pdfAbsPaths, path.resolve(Config.txt_dir), addFilesToDB);
})
