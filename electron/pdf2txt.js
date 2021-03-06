'use strict';

// needed for async
require("babel-polyfill");

const mkdirp = require('mkdirp');

// does not work if PDFJS is in local. Fix later.
var PDFJS = require('./pdfjs/build/pdf.js');
PDFJS.workerSrc = './pdfjs/build/pdf.worker.js';
PDFJS.cMapUrl = '../web/cmaps/';
PDFJS.cMapPacked = true;

var pdf2txt = (function () {

  const fs = require('fs');
  const path = require('path');

  // For recording of progress
  var numPdfTotal = 0;
  var counterProgress = 0;

  // Concatenate text items to single text
  var catText = function (textItems) {
      var text = '';
      for (var i=0; i < textItems.length; i++) {
        text += textItems[i].str + '\n';
      }
      return text;
  }

  var cleanText = function (str) {
      // Dirty, fix later
      function keepExpr (str, re, key) {
        return str.replace(re, key)
      }

      function restoreExpr (str, key, restoreChar) {
        var re = new RegExp(key, 'g');
        return str.replace(re, restoreChar);
      }

      // Remove spaces surrounded by non-ascii character
      function removeSpace (str) {
        const re1 = /([^\x00-\x7F]) +/g; // non-ascii + space
        const re2 = / +([^\x00-\x7F])/g; // space + non-ascii
        const re3 = / +/g;               // trailing spaces
        return str.replace(re1, '$1').replace(re2, '$1').replace(re3, ' ');
      }

      // Keep some expressions
      var strKeep = keepExpr(str, /。\n/g, '#punctNewLine');
      strKeep = keepExpr(strKeep, /\n\n/g, '#doubleNewLine');
      strKeep = keepExpr(strKeep, /\n　/g, '#newLineSpace');

      // Remove remaining all newlines
      var strConv = strKeep.replace(/\n/g, '');

      // Remove redundant spaces
      strConv = removeSpace(strConv);

      // Restore expr
      strConv = restoreExpr(strConv, '#punctNewLine', '。\n');
      strConv = restoreExpr(strConv, '#doubleNewLine', '\n\n');
      strConv = restoreExpr(strConv, '#newLineSpace', '\n　');
      return strConv
  }

  var getUniqueTextBox = function (items) {
      function strExp(item) {
        return item.str + item.transform.toString();
      }
      var uniqueItems = [];
      var isSame = false;
      for (var i=0; i < items.length; i++) {
        var targetStr = strExp(items[i]);
        for (var uniqueItem of uniqueItems) {
          if (strExp(uniqueItem) == targetStr) {
            isSame = true;
            break;
          }
        }
        if (!isSame) {
          uniqueItems.push(items[i]);
        }
        isSame = false;
      }
      return uniqueItems;
  }

  return {
    // Get only a specified page of pdf
    extractTextPage: function (pdfPath, pageNum) {
      return PDFJS.getDocument(pdfPath).then(
        (pdfDoc) => pdfDoc.getPage(pageNum)).then(
          (pdfPage) => pdfPage.getTextContent()).then(
            (textContent) => {
              var uniqueTextBoxes = getUniqueTextBox(textContent.items);
              return cleanText(catText(uniqueTextBoxes));
            })
    },

    // Extract and save all pages
    extractSaveAll: function (pdfPath, saveDir) {
      console.log(pdfPath);
      var prog = counterProgress / numPdfTotal;
      counterProgress += 1;
      fs.writeFileSync('progress_text_extraction', prog);
      //fs.writeFileSync('progress_text_extraction', pdfPath);
      return PDFJS.getDocument(pdfPath).then(
        (pdfDoc) => {
          var pageNums = pdfDoc.numPages;
          var promises = [];
          for (var pageNum = 1; pageNum < pageNums + 1; pageNum++) {
            promises.push(pdfDoc.getPage(pageNum).then(
              (pdfPage) => pdfPage.getTextContent()).then(
                (textContent) => {
                  var uniqueTextBoxes = getUniqueTextBox(textContent.items);
                  var saveText = cleanText(catText(uniqueTextBoxes));
                  return saveText;
                }))
          }
          return Promise.all(promises).then(
            (saveTexts) => {
              var savePaths = [];
              for (var i=0; i < saveTexts.length; i++) {
                var ext = path.extname(pdfPath);
                var pdfName = path.basename(pdfPath, ext);
                var saveFileName = pdfName + '_p' + (i + 1).toString() + '.txt';

                // save to txt/pdfName/*.txt
                var dstDir = path.join(path.resolve(saveDir), pdfName);
                mkdirp(dstDir);
                var savePath =  path.join(dstDir, saveFileName);

                console.log(savePath);
                savePaths.push(savePath);
                var retry = 0;
                while (true) {
                  if (retry > 10) { throw "Retry failed too many times." }
                  try {
                    fs.writeFileSync(savePath, saveTexts[i]);
                  }
                  catch (e) {
                    console.log(e);
                    console.log('Retry.');
                    retry += 1;
                    continue;
                  }
                  break;
                }
              }
              console.log('Finished.');
              return savePaths;
            })
        })
    },


    // find pdf files in a directory, extract texts.
    extractFromDirectory: function (docDir, saveDir) {
      if (!fs.existsSync(docDir)) {
        throw 'Error: ' + docDir + ' not exist';
      }
      if (!fs.existsSync(saveDir)) {
        fs.mkdirSync(saveDir);
      }
      var filePaths = fs.readdirSync(docDir);
      var pdfPaths = [];
      for (let filePath of filePaths) {
        var fileName = path.basename(filePath);
        var ext = path.extname(filePath);
        if (['.pdf', '.PDF'].indexOf(ext) >= 0) {
          pdfPaths.push(path.join(docDir, fileName));
        }
      }
      pdf2txt.pdfFilesTotxt(pdfPaths, saveDir);
    },

    // extract texts from multiple pdf files
    pdfFilesTotxt: function (pdfPaths, saveDir, callback) {
      (async () => {
        var paths = [];
        numPdfTotal = pdfPaths.length
        counterProgress = 0
        for (let pdfPath of pdfPaths) {
          var res = await pdf2txt.extractSaveAll(pdfPath, saveDir);
          paths = paths.concat(res).concat(pdfPath);
        }
        return paths;
      })().then(paths => {
        console.log('Finished all.');
        fs.writeFileSync('progress_text_extraction', 'Finished');
        callback(paths);  // Add to db, both text and pdfs
      }).catch((err) => {
        console.log('Failed');
        console.log(err);
      });
    }
  }
})()
