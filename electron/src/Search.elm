module Search exposing (..)

import Http
import Json.Decode exposing (int, string, float, bool, nullable, map, map2, map3, map4, map5, field, at, list, Decoder)

import Models exposing (SearchResult, SearchResultRow, IndexResult, IndexResultRow, ResultMessage)
import Messages exposing (Msg(..))


-- JSON decoders

searchResponseDecoder : Decoder SearchResult
searchResponseDecoder =
  let
    rowDecoder =
      map5 SearchResultRow (field "title" string) (field "file_path" string) (field "parent_file_path" string) (field "page" int) (field "highlighted_body" string)
  in
    map3 SearchResult (at ["rows"] <| list rowDecoder) (at ["n_hits"] <| int) (at ["total_pages"] <| int)

indexResultDecoder : Decoder IndexResult
indexResultDecoder =
  let
    rowDecoder =
      map5 IndexResultRow (field "title" string) (field "file_path" string) (field "summary" string) (field "created_at" string) (field "gid" string)
  in
    map3 IndexResult (at ["rows"] <| list rowDecoder) (at ["n_docs"] <| int) (at ["total_pages"] <| int)

messageDecoder : Decoder ResultMessage
messageDecoder =
  at ["message"] <| string

progressDecoder : Decoder String
progressDecoder =
  at ["message"] <| string



-- HTTP

search : String -> Int -> String -> Int -> Cmd Msg
search query numResultPage sortField reverse =
  let
      url =
        "http://localhost:8000/search?q=" ++ query ++ "&sort_field=" ++ sortField
          ++ "&reverse=" ++ (toString reverse)
          ++ "&result-page=" ++ (toString numResultPage)
  in
      Http.send NewSearchResult (Http.get url searchResponseDecoder)

getIndex : String -> Int -> Int -> Cmd Msg
getIndex sortField numResultPage reverse =
  let
      url =
        "http://localhost:8000/sorted-index?field=" ++ sortField
          ++ "&reverse=" ++ (toString reverse)
          ++ "&result-page=" ++ (toString numResultPage)
  in
      Http.send NewIndexResult (Http.get url indexResultDecoder)

deleteDocument : String -> Cmd Msg
deleteDocument gid =
  let
      url =
        "http://localhost:8000/delete?gid=" ++ gid
  in
      Http.send DeleteResult (Http.get url messageDecoder)

getProgress : Cmd Msg
getProgress =
  let
      url =
        "http://localhost:8000/progress"
  in
      Http.send GetProgress (Http.get url progressDecoder)
