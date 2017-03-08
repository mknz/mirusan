'use strict';

const fs = require('fs');
const path = require('path');

// Generate config file
const baseWorkDir = process.cwd();
const configPath = path.join(baseWorkDir, 'config.json');
if (!fs.existsSync(configPath)) {
  var Config = {};
  Config.data_dir = './data';
  Config.pdf_dir = './data/pdf';
  Config.txt_dir = './data/txt';
  Config.mode = 'release';
  Config.locale = 'en';
  fs.writeFileSync(configPath, JSON.stringify(Config, null, 2));
} else {
  var Config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
}

if (Config.mode === 'debug') {
  var debug = true;
} else {
  var debug = false;
}

// i18n
const i18n = require('i18n');
i18n.configure({
  locales: ['en', 'ja'],
  defaultLocale: Config.locale,
  directory: __dirname + "/locales_mirusan",
  objectNotation: true
});

var log = require('electron-log');
log.transports.file.file = path.join(baseWorkDir, 'mirusan_electron.log');
log.transports.file.streamConfig = { flags: 'w' };
log.transports.file.maxSize = 5 * 1024 * 1024;
log.transports.file.format = '{y}-{m}-{d} {h}:{i}:{s}:{ms} [{level}] {text}';
if (debug) {
  log.transports.file.level = 'debug';
} else {
  log.transports.file.level = 'warn';
}

// Electron libraries
const electron = require('electron');
const {ipcMain, dialog} = require('electron');

// Auto update
const autoUpdater = require('electron-updater').autoUpdater;

autoUpdater.logger = require('electron-log');
if (debug) {
  autoUpdater.logger.transports.file.level = 'debug';
 } else { autoUpdater.logger.transports.file.level = 'warn';
}

autoUpdater.checkForUpdates();

autoUpdater.on('update-downloaded', () => {
  index = dialog.showMessageBox({
    message: i18n.__('Software update has been downloaded.'),
      detail: i18n.__('Install update and reboot?'),
      buttons: [i18n.__('Reboot'), i18n.__('Later')]
    });
    if (index === 0) {
      autoUpdater.quitAndInstall();
    }
});

autoUpdater.on('error', (err) => {
  log.error(err);
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
} else if (process.platform == 'linux' || process.platform == 'darwin') {
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

  win.loadURL('file://' + __dirname + '/index.html');

  if (debug) { win.webContents.openDevTools(); }

  win.on('closed', function() {
   console.log(i18n.__('Closing main window.'));
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

  win.loadURL('file://' + __dirname + '/background.html');

  if (debug) { win.webContents.openDevTools(); }

  win.on('closed', function() {
   console.log(i18n.__('Closing background window.'));
   win = null;
  });
  return win;
}

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
    console.log(i18n.__('Killing subprocess.'));
    const killer = require('child_process').exec;
    killer('taskkill /im mirusan_search.exe /f /t', (err, stdout, stderr) => {
      log.err(err);
      log.err(stderr);
      log.info(stdout);
    });
  } else if (process.platform == 'linux' || process.platform == 'darwin') {
    console.log(i18n.__('Killing subprocess.'));
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
