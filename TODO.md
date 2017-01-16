- pdfにおける日本語処理にはcmap読み込みが必要

- pdf.jsはwebworker内でcmapの読み込みを行う

- nodeを使ってコマンドラインツールとして実行したときにwebworkerが使用できない

- とりあえずelectronで動かす・・・
