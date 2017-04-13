module Messages exposing (..)

import Models exposing (SearchResult, IndexResult, IndexResultRow, ResultMessage)
import Http
import Time exposing (Time)
import Window exposing (Size)
import Mouse exposing (Position)


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
  | OpenItemDialog IndexResultRow
  | DeleteDocument
  | CancelDeleteDocument
  | DeleteResult (Result Http.Error ResultMessage)
  | PdfUrl String
  | GetProgress (Result Http.Error String)
  | CheckProgress Time
  | CheckWindowSize Size
  | DragStart Position
  | DragAt Position
  | DragEnd Position
  | DragNothing Position
