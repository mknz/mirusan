module Messages exposing (..)

import Models exposing (SearchResult, IndexResult)
import Http


type Msg
  = SendSearch String
  | NewSearchResult (Result Http.Error SearchResult)
  | GetNextResultPage
  | GetPrevResultPage
  | GotoResultPage String
  | OpenDocument (String, Int)
  | AddFilesToDB
  | GetIndex
  | NewIndexResult (Result Http.Error IndexResult)
