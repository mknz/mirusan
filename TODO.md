# TODO

## pdf.js
- pdfにおける日本語処理にはcmap読み込みが必要

- pdf.jsはwebworker内でcmapの読み込みを行う

- nodeを使ってコマンドラインツールとして実行したときにwebworkerが使用できない

- とりあえずelectronで動かす・・・

## テキスト処理
- 文章内に無意味な半角スペースが含まれている場合の処理

- テキストブロックのつながりの自動判定
  + 大変なのであとまわし

## known problems
- 150個程度以上のpdf変換を同時に行うと、asyncを使っているにもかかわらずメモリエラーでelecronが落ちる
