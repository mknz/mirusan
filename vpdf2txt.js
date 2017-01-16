// does not work if PDFJS is in local. Fix later.
var PDFJS = require('./node_modules/pdfjs-dist');
PDFJS.workerSrc = './node_modules/pdfjs-dist/build/pdf.worker.js';
PDFJS.cMapUrl = '../cmaps/';
PDFJS.cMapPacked = true;

vpdf2txt = (function () {
  var fs = require('fs');
  var path = require('path');

  // Concatinate text items to single text
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

      // Keep some expressions
      var strKeep = keepExpr(str, /。\n/g, '#punctNewLine');
      strKeep = keepExpr(strKeep, /\n\n/g, '#dubbleNewLine');
      strKeep = keepExpr(strKeep, /\n　/g, '#NewLineSpace');

      // Remove remaining all newlines
      var strConv = strKeep.replace(/\n/g, '');

      // Restore expr
      strConv = restoreExpr(strConv, '#punctNewLine', '。\n');
      strConv = restoreExpr(strConv, '#dubbleNewLine', '\n\n');
      strConv = restoreExpr(strConv, '#NewLineSpace', '\n　');
      return strConv
  }

  var getUniqueTextBox = function (items) {
      function strExp(item) {
        return item.str + item.transform.toString();
      }
      var uniqueItems = [];
      var isSame = false;
      for (var i=0; i < items.length; i++) {
        targetStr = strExp(items[i]);
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
      PDFJS.getDocument(pdfPath).then(
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
          Promise.all(promises).then(
            (saveTexts) => {
              for (var i=0; i < saveTexts.length; i++) {
                var pdfName = path.basename(pdfPath).split('.').shift();
                var saveFileName = pdfName + '_p' + (i + 1).toString() + '.txt';
                var savePath =  path.join(saveDir, saveFileName);
                console.log(savePath);
                fs.writeFileSync(savePath, saveTexts[i]);
              }
              console.log('Finished.');
            })
        })
    },

    // process all pdf files in docDir
    processAll: function (docDir, saveDir) {
      if (!fs.existsSync(docDir)) {
        throw 'Error: ' + docDir + ' not exist';
      }
      if (!fs.existsSync(saveDir)) {
        fs.mkdirSync(saveDir);
      }
      var filePaths = fs.readdirSync(docDir);
      var pdfPaths = [];
      for (var filePath of filePaths) {
        var fileName = path.basename(filePath);
        if (['pdf', 'PDF'].indexOf(fileName.split('.').pop()) >= 0) {
          pdfPaths.push(path.join(docDir, fileName));
        }
      }
      for (pdfPath of pdfPaths) {
        vpdf2txt.extractSaveAll(pdfPath, saveDir);
      }
    }
  }
})()

var docDir =  './data/pdf';
var saveDir = './data/text';
vpdf2txt.processAll(docDir, saveDir);
