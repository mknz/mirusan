'use strict';

const debug = true;

// Electron libraries
const electron = require('electron');
const {ipcMain, dialog} = require('electron');

// Auto update
const autoUpdater = require('electron-updater').autoUpdater;

autoUpdater.logger = require('electron-log');
if (debug) {
  autoUpdater.logger.transports.file.level = 'info';
 } else {
  autoUpdater.logger.transports.file.level = 'error';
}

autoUpdater.checkForUpdates();

autoUpdater.on('update-downloaded', () => {
  index = dialog.showMessageBox({
    message: 'Software update has been downloaded.',
      detail: 'Install update and reboot?',
      buttons: ['Reboot', 'Later']
    });
    if (index === 0) {
      autoUpdater.quitAndInstall();
    }
});

autoUpdater.on('update-not-available', () => {
  dialog.showMessageBox({
    message: 'There was no update.',
      buttons: ['OK']
  });
});

autoUpdater.on('error', () => {
  dialog.showMessageBox({
    message: 'Error during Update.',
      buttons: ['OK']
  });
});

// Module to control application life.
const app = electron.app;
// Module to create native browser window.
const BrowserWindow = electron.BrowserWindow;

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow;

if (process.platform == 'win32') {
  var subpy = require('child_process').spawn('./mirusan_search.exe', ['--server']);
} else if (process.platform == 'linux') {
  var subpy = require('child_process').spawn('python3', ['../search/search.py', '--server']);
}

/**
 * [createWindow description]
 * @method createWindow
 */
function createWindow() {
  // Create the browser window.
  let win = new BrowserWindow({width: 1000, height: 700});

  if (!debug) { win.setMenu(null); }

  // and load the index.html of the app.
  win.loadURL('file://' + __dirname + '/index.html');

  if (debug) { win.webContents.openDevTools(); }

  // Emitted when the window is closed.
  win.on('closed', function() {
   console.log('Closing window.');
   win = null;
  });
  return win;
}

function createBackgroundWindow(parentWindow) {
  if (debug) {
    var win = new BrowserWindow({width: 300, height: 700, parent: parentWindow});
  } else {
    var win = new BrowserWindow({width: 0, height: 0, show: false, parent: parentWindow});
  }

  // and load the index.html of the app.
  win.loadURL('file://' + __dirname + '/bg.html');

  if (debug) { win.webContents.openDevTools(); }

  // Emitted when the window is closed.
  win.on('closed', function() {
   console.log('Closing window.');
   win = null;
  });
  return win;
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
app.on('ready', () => {
  const mainWindow = createWindow();
  const bgWindow = createBackgroundWindow(mainWindow);
  ipcMain.on('pdf-extract-request-main', (event, arg) => {
    dialog.showOpenDialog({filters: [{name: 'PDF files', extensions: ['pdf', 'PDF']}],
                           properties: ['openFile', 'multiSelections']},
                           (filePaths) => {
                             bgWindow.webContents.send('pdf-extract-request-background',
                             { pdfPaths: filePaths });
                           })
  });
})

// Quit when all windows are closed.
app.on('window-all-closed', function() {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit();
  }
  if (process.platform == 'win32') {
    console.log('Killing subprocess.');
    const killer = require('child_process').execSync;
    killer('taskkill /im mirusan_search.exe /f /t', (err, stdout, stderr) => {
      console.log(err);
      console.log(stderr);
      console.log(stdout);
    });
  } else if (process.platform == 'linux') {
    console.log('Killing subprocess.');
    subpy.kill('SIGINT');
  }
});

app.on('activate', function() {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (mainWindow === null) {
    createWindow();
  }
});
