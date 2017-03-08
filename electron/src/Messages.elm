module Messages exposing (..)

import Models exposing (SearchResult, IndexResult, ResultMessage)
import Http


type Msg
  = SendSearch String
  | NewSearchResult (Result Http.Error SearchResult)
  | GetNextResultPage
  | GetPrevResultPage
  | GotoResultPage String
  | OpenDocument (String, Int)
  | AddFilesToDB
  | ShowIndex
  | GotoSearchMode
  | NewIndexResult (Result Http.Error IndexResult)
  | DeleteDocument String
  | DeleteResult (Result Http.Error ResultMessage)
