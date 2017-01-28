port module Main exposing (..)

import Electron.IpcRenderer as IPC exposing (on, send)

import Html exposing (Html, program, text, button, h1, h2, div, input, a, span, p, header, iframe, nav)
import Html.Attributes exposing (class, id, type_, placeholder, value, href, style, src, title)
import Html.Events exposing (onClick, onInput)
import Json.Encode
import Json.Decode exposing (int, string, float, bool, nullable, map, map2, field, at, list, Decoder)
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
    searchResult: SearchResult,
    serverMessage: String
  }

type alias SearchResultRow =
  { fileName: String,
    body: String
  }

type alias SearchResult = List SearchResultRow

init : ( Model, Cmd Msg )
init =
  ({ currentQuery = "", searchResult = [], serverMessage = "" }, Cmd.none)


-- UPDATE


type Msg
  = SendSearch String
  | NewSearchResult (Result Http.Error SearchResult)
  | OpenDocument String
  | GetFilesToAddDB
  | FilesToAddDB (List String)
  | AddDBResult (Result Http.Error String)

port openNewFile : String -> Cmd msg
port getFilesToAddDB : Bool -> Cmd msg

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
    GetFilesToAddDB ->
      ( model, getFilesToAddDB True)
    FilesToAddDB paths ->
      ( model, addFilesToDB paths )
    AddDBResult (Ok res) ->
      ( { model | serverMessage = res }, Cmd.none )
    AddDBResult (Err _) ->
      ( { model | serverMessage = "error" }, Cmd.none )

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

      toolbarHeader =
        header [ class "toolbar toolbar-header" ] [ toolbarActions ]

      addFileButton =
        button [ class "btn btn-default", onClick GetFilesToAddDB, title "Add files to database" ] [ span [ class "icon icon-folder" ] [] ]

      toolButtons =
        div [ class "btn-group" ] [ addFileButton ]

      toolbarActions =
        div [ class "toolbar-actions" ] [ div [ class "btn-group" ] [ searchWindow ], toolButtons ]

      sidebarContainer =
        div [ id "sidebar-container" ] [ div [ id "search" ]  searchResultDisplay ]

      viewerIframe =
        iframe [ id "pdf-viewer", style [ ("width", "100%"), ("height", "100%") ], src "./pdfjs/web/viewer.html" ] []

      viewerContainer =
        div [ id "pdf-viewer-container" ] [ viewerIframe ]

      searchWindow =
        span [] [ input [ type_ "text", placeholder "Search", onInput SendSearch ] []
        , span [ style [ ("font-size", "15pt") ] ] [ text " " ]
        , span [ class "icon icon-search", style [ ("vertical-align", "middle"), ("font-size", "15pt") ] ] []
        ]

  in
      div []  [toolbarHeader, sidebarContainer, viewerContainer]

-- SUBSCRIPTIONS

port filesToAddDB : (List String -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [
    filesToAddDB FilesToAddDB
  ]


-- HTTP

search : String -> Cmd Msg
search query =
  let
      url =
        "http://localhost:8000/search?query=" ++ query
  in
      Http.send NewSearchResult (Http.get url searchResponseDecoder)

addFileToDB : String -> Cmd Msg
addFileToDB path =
  let
      url =
        "http://localhost:8000/add-file?file=" ++ path
  in
      Http.send AddDBResult (Http.get url addFileToDBResponseDecoder)

addFilesToDB : (List String) -> Cmd Msg
addFilesToDB paths =
  Cmd.batch (List.map addFileToDB paths)


-- JSON decoders

rowDecoder =
  map2 SearchResultRow (field "file-name" string) (field "body" string)

searchResponseDecoder : Decoder SearchResult
searchResponseDecoder =
  at ["results"] <| list rowDecoder

addFileToDBResponseDecoder : Decoder String
addFileToDBResponseDecoder =
  at ["exit-status"] <| string
