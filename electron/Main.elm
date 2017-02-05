port module Main exposing (..)

import Electron.IpcRenderer as IPC exposing (on, send)

import Html exposing (Html, program, text, button, h1, h2, div, input, a, span, p, header, iframe, nav)
import Html.Attributes exposing (class, id, type_, placeholder, value, href, style, src, title)
import Html.Events exposing (onClick, onInput)
import Json.Encode
import Json.Decode exposing (int, string, float, bool, nullable, map, map2, map3, map4, field, at, list, Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode
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
    numResultPage: Int,
    searchResult: SearchResult,
    serverMessage: String
  }

type alias SearchResult =
  { rows: List SearchResultRow,
    nHits: Int,
    totalPages: Int
  }

type alias SearchResultRow =
  { title: String,
    fileName: String,
    numPage: Int,
    body: String
  }


-- JSON decoders

rowDecoder =
  map4 SearchResultRow (field "title" string) (field "document_file_name" string) (field "page" int) (field "highlighted_body" string)

searchResponseDecoder : Decoder SearchResult
searchResponseDecoder =
  map3 SearchResult (at ["rows"] <| list rowDecoder) (at ["n_hits"] <| int) (at ["total_pages"] <| int)


-- Init

init : ( Model, Cmd Msg )
init =
  ({ currentQuery = "", numResultPage = 1, searchResult = { rows = [], nHits = 0, totalPages = 0 }, serverMessage = "" }, Cmd.none)


-- UPDATE

type Msg
  = SendSearch String
  | NewSearchResult (Result Http.Error SearchResult)
  | GetNextResultPage
  | GetPrevResultPage
  | GotoResultPage String
  | OpenDocument (String, Int)
  | AddFilesToDB

port openNewFile : (String, Int) -> Cmd msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SendSearch query ->
      ( { model | currentQuery = query }, search query model.numResultPage )
    NewSearchResult (Ok res) ->
      ( { model | searchResult = res }, Cmd.none )
    NewSearchResult (Err _) ->
      ( { model | numResultPage = 1, searchResult = { rows = [], nHits = 0, totalPages = 0 } }, Cmd.none )

    GetNextResultPage ->
    -- pagenation
      if model.numResultPage < model.searchResult.totalPages then
        ( { model | numResultPage = model.numResultPage + 1 }, search model.currentQuery model.numResultPage )
      else  -- last page
        ( model , Cmd.none )

    GetPrevResultPage ->
    -- pagenation
      if model.numResultPage > 1 then
        ( { model | numResultPage = model.numResultPage - 1 }, search model.currentQuery model.numResultPage )
      else  -- last page
        ( model , Cmd.none )

    GotoResultPage inputStr ->
      case String.toInt inputStr of
        (Ok n) ->
          if n < 1 then
          -- Go to first page
            ( { model | numResultPage = 1 }, search model.currentQuery 1 )
          else if n >= 1 && n <= model.searchResult.totalPages then
          -- Go to specified page
            ( { model | numResultPage = n }, search model.currentQuery n )
          else
          -- Go to last page
            ( { model | numResultPage = model.searchResult.totalPages }, search model.currentQuery model.searchResult.totalPages )

        (Err str) ->
          ( model , Cmd.none )

    OpenDocument (fileName, numPage) ->
      ( model, openNewFile (fileName, numPage) )
    AddFilesToDB ->
    -- send request to electron main process
      ( model, IPC.send "pdf-extract-request-main" Json.Encode.null)

-- VIEW

view : Model -> Html Msg
view model =
  let
      createComponent row =
        let
          sBody = row.title ++ " (p" ++ toString row.numPage ++  "): " ++ row.body
        in
          div [] [ div [ class "search-result", onClick (OpenDocument (row.fileName, row.numPage)) ] [ Markdown.toHtml [] sBody ]
          ]

      searchResultDisplay =
        List.map createComponent model.searchResult.rows

      toolbarHeader =
        header [ class "toolbar toolbar-header" ] [ toolbarActions ]

      addFileButton =
        button [ class "btn btn-default", onClick AddFilesToDB, title "Add files to database" ] [ span [ class "icon icon-folder" ] [] ]

      toolButtons =
        div [ class "btn-group" ] [ addFileButton ]

      toolbarActions =
        div [ class "toolbar-actions" ] [ div [ class "btn-group" ] [ searchWindow ], toolButtons, span [] [ text model.serverMessage ] ]

      searchResultSummary =
        let
          resPageStr = (toString model.numResultPage) ++ " page of " ++ (toString model.searchResult.totalPages)
          hitsStr = "(" ++ (toString model.searchResult.nHits) ++ " hits" ++ ")"
        in
          div [] [ div [] [ text (resPageStr ++ " " ++ hitsStr) ] ]

      pagenation =
        let
          prevPageButton = button [ class "btn btn-default", onClick GetPrevResultPage ] [ text "Prev" ]
          nextPageButton = button [ class "btn btn-default", onClick GetNextResultPage ] [ text "Next" ]
          prevPageButtonDisabled = button [ class "btn btn-default gray" ] [ text "Prev" ]
          nextPageButtonDisabled = button [ class "btn btn-default gray" ] [ text "Next" ]
          inputPage = input [ type_ "text", placeholder "page", onInput GotoResultPage ] []
        in
          if model.numResultPage == 1 then
            div [] [ prevPageButtonDisabled, nextPageButton, inputPage ]
          else if model.numResultPage == model.searchResult.totalPages then
            div [] [ prevPageButton, nextPageButtonDisabled, inputPage ]
          else if model.searchResult.nHits == 0 then
            div [] [ prevPageButtonDisabled, nextPageButtonDisabled, inputPage ]
          else
            div [] [ prevPageButton, nextPageButton, inputPage ]

      sidebarContainer =
        div [ id "sidebar-container" ] [ div [ id "search" ]  ( List.append [ searchResultSummary, pagenation ] searchResultDisplay )  ]

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
--port filesToAddDB : (List String -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [
    --filesToAddDB FilesToAddDB
  ]


-- HTTP

search : String -> Int -> Cmd Msg
search query numResultPage =
  let
      url =
        "http://localhost:8000/search?q=" ++ query ++ "&resultPage=" ++ (toString numResultPage)
  in
      Http.send NewSearchResult (Http.get url searchResponseDecoder)

