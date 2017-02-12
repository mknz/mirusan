# Mirusan
![mirusan_logo.png](images/mirusan_logo.png)

A PDF collection reader with built-in full text search engine

## Features

- Quick incremental search

- Simple UI

- Local database (You have controll 100% of your data)

- Easy installation (No need of external databases or tools)

- Multiplatform (Linux, Mac, Windows)

## Quickstart

```sh
#install python3
#install node.js

git clone https://github.com/mknz/mirusan.git

cd ./mirusan
cd ./search
pip install -r requirements.txt

cd ../electron
npm install
npm run compile

npm start
```

## License

[GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)

## Acknowledgements
[Whoosh (Pure Python search engine library)](http://whoosh.readthedocs.io/en/latest/)

[pdf.js](https://github.com/mozilla/pdf.js)

[Electron](http://electron.atom.io/)

[Photon](http://photonkit.com/)

[Elm](http://elm-lang.org/)

[elm-electron](https://github.com/elm-electron/electron/tree/master/examples/ipcRenderer)
