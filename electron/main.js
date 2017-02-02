'use strict';

// Electron libraries
const electron = require('electron');
const {ipcMain} = require('electron');

// Module to control application life.
const app = electron.app;
// Module to create native browser window.
const BrowserWindow = electron.BrowserWindow;

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow;

if (process.platform == 'win32') {
  var subpy = require('child_process').spawn('./mirusan_search.exe', ['--server']);
}

/**
 * [createWindow description]
 * @method createWindow
 */
function createWindow() {
  // Create the browser window.
  mainWindow = new BrowserWindow({width: 1000, height: 700});
  //mainWindow.setMenu(null);

  // and load the index.html of the app.
  mainWindow.loadURL('file://' + __dirname + '/index.html');

  // for debug
  mainWindow.webContents.openDevTools()

  // Emitted when the window is closed.
  mainWindow.on('closed', function() {
    if (process.platform == 'win32') {
      console.log('Killing subprocess.');
      const killer = require('child_process').execSync;
      killer('taskkill /im mirusan_search.exe /f /t', (err, stdout, stderr) => {
        console.log(err);
        console.log(stderr);
        console.log(stdout);
      });
   }
   console.log('Closing window.');
   mainWindow = null;
  });
}

/**
 * Initializes the app:
 *   - Get or create user settings database
 *   - Create app main windows
 */
function initialize() {
  createWindow();
};

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
app.on('ready', initialize);

// Quit when all windows are closed.
app.on('window-all-closed', function() {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', function() {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (mainWindow === null) {
    createWindow();
  }
});


ipcMain.on('time-request', (event, arg) => {
  let t;

  if (arg['format'] == "timestamp") {
    t = Date.now().toString();
  } else if (arg['format'] == 'openPdf') {

  } else {
    t = Date().toLocaleString();
  }

  event.sender.send('time-response', {
    status: "success",
    time: t
  });
});
