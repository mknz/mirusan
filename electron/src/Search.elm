module Search exposing (..)

import Http
import Json.Decode exposing (int, string, float, bool, nullable, map, map2, map3, map4, field, at, list, Decoder)

import Models exposing (SearchResult, SearchResultRow, IndexResult, IndexResultRow)
import Messages exposing (Msg(..))


-- JSON decoders

searchResponseDecoder : Decoder SearchResult
searchResponseDecoder =
  let
    rowDecoder =
      map4 SearchResultRow (field "title" string) (field "document_file_name" string) (field "page" int) (field "highlighted_body" string)
  in
    map3 SearchResult (at ["rows"] <| list rowDecoder) (at ["n_hits"] <| int) (at ["total_pages"] <| int)

indexResultDecoder : Decoder IndexResult
indexResultDecoder =
  let
    rowDecoder =
      map3 IndexResultRow (field "title" string) (field "document_file_name" string) (field "created_at" string)
  in
    map3 IndexResult (at ["rows"] <| list rowDecoder) (at ["n_docs"] <| int) (at ["total_pages"] <| int)

-- HTTP

search : String -> Int -> Cmd Msg
search query numResultPage =
  let
      url =
        "http://localhost:8000/search?q=" ++ query ++ "&resultPage=" ++ (toString numResultPage)
  in
      Http.send NewSearchResult (Http.get url searchResponseDecoder)

getIndex : String -> Int -> Cmd Msg
getIndex fieldName numResultPage =
  let
      url =
        "http://localhost:8000/sorted-index?field=" ++ fieldName ++ "&resultPage=" ++ (toString numResultPage)
  in
      Http.send NewIndexResult (Http.get url indexResultDecoder)
