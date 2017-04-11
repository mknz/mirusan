module Messages exposing (..)

import Models exposing (SearchResult, IndexResult, ResultMessage)
import Http
import Time exposing (Time)
import Window exposing (Size)


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
  | AskDeleteDocument String
  | DeleteDocument
  | CancelDeleteDocument
  | DeleteResult (Result Http.Error ResultMessage)
  | PdfUrl String
  | GetProgress (Result Http.Error String)
  | CheckProgress Time
  | CheckWindowSize Size
