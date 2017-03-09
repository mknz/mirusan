module Translation exposing
  ( Language (..)
  , TranslationId (..)
  , translate
  )

type alias TranslationSet =
  { english : String
  , japanese : String
  }

type TranslationId
  = I18n_Go_to_search
    | I18n_Show_index
    | I18n_Add_files_to_database
    | I18n_Search
    | I18n_page
    | I18n_Ask_delete

type Language
  = English
  | Japanese

translate : Language -> TranslationId -> String
translate lang trans =
  let
    translationSet =
      case trans of
        I18n_Go_to_search ->
          TranslationSet "Go to search mode" "検索モードへ"
        I18n_Show_index ->
          TranslationSet "Show index" "一覧を表示"
        I18n_Add_files_to_database ->
          TranslationSet "Add files to database" "ファイルを追加する"
        I18n_Search ->
          TranslationSet "Search" "検索"
        I18n_page ->
          TranslationSet "page" "ページへ"
        I18n_Ask_delete ->
          TranslationSet "Delete this document?" "この文書を削除しますか？"
  in
    case lang of
      English ->
        .english translationSet
      Japanese ->
        .japanese translationSet

