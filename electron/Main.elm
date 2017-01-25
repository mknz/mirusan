port module Main exposing (..)

import Electron.IpcRenderer as IPC exposing (on, send)

import Html exposing (Html, program, text, button, h1, h2, div, input, a)
import Html.Attributes exposing (class, type_, placeholder, value, href, style)
import Html.Events exposing (onClick, onInput)
import Json.Encode
import Json.Decode exposing (int, string, float, nullable, map, map2, field, at, list, Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Http
import Markdown


main =
  program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL


type alias Model =
  { currentQuery: String,
    searchResult: SearchResult
  }

type alias SearchResultRow =
  { fileName: String,
    body: String
  }

type alias SearchResult = List SearchResultRow

init : ( Model, Cmd Msg )
init =
  ({ currentQuery = "", searchResult = [] }, Cmd.none)


-- UPDATE


type Msg
  = SendSearch String
  | NewSearchResult (Result Http.Error SearchResult)
  | OpenDocument String

port openNewFile : String -> Cmd msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SendSearch query ->
      ( { model | currentQuery = query }, search query )
    NewSearchResult (Ok res) ->
      ( { model | searchResult = res }, Cmd.none )
    NewSearchResult (Err _) ->
      ( { model | searchResult = [] }, Cmd.none )
    OpenDocument fileName->
      ( model, openNewFile fileName )


-- VIEW

view : Model -> Html Msg
view model =
  let
      createComponent row =
        let
          sBody = row.fileName ++ ": " ++ row.body
        in
          div [] [ div [ class "search-result", onClick (OpenDocument row.fileName) ] [ Markdown.toHtml [] sBody ]
          ]

      searchResultDisplay =
        List.map createComponent model.searchResult

      mainDivs =
        List.append
        [ input [ type_ "text", placeholder "Search", onInput SendSearch ] []
        ] searchResultDisplay

  in
      div [] mainDivs

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [ --IPC.on "time-response" (map OnResponse decodeResponse)
    Sub.none
  ]


-- HTTP

search : String -> Cmd Msg
search query =
  let
      url =
        "http://localhost:8000/search?query=" ++ query
  in
      Http.send NewSearchResult (Http.get url searchResponseDecoder)


-- JSON decoders

rowDecoder =
  map2 SearchResultRow (field "file-name" string) (field "body" string)

searchResponseDecoder : Decoder SearchResult
searchResponseDecoder =
  at ["results"] <| list rowDecoder
