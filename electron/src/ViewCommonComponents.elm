module ViewCommonComponents exposing (..)

import Html exposing (Html, program, text, button, h1, h2, div, input, a, span, p, header, iframe, nav)
import Html.Attributes exposing (class, id, type_, placeholder, value, href, style, src, title, size)
import Html.Events exposing (onClick, onInput)

import Models exposing (Model)
import Messages exposing (Msg(..))


toolbarHeader mode messageStr =
  header [ class "toolbar toolbar-header" ] [ toolbarActions messageStr mode ]

toolbarActions messageStr mode =
  div [ class "toolbar-actions" ] [ div [ class "btn-group" ] [ searchWindow ], toolButtons mode, span [] [ text messageStr ] ]

toolButtons mode =
  div [ class "btn-group" ] [ showIndexButton mode, addFileButton ]

showIndexButton mode =
  case mode of
    Models.IndexMode ->
      button [ class "btn active btn-large btn-default", onClick GotoSearchMode, title "Go to search" ] [ span [ class "icon icon-list" ] [] ]
    Models.SearchMode ->
      button [ class "btn btn-large btn-default", onClick ShowIndex, title "Show index" ] [ span [ class "icon icon-list" ] [] ]

addFileButton =
  button [ class "btn btn-large btn-default", onClick AddFilesToDB, title "Add files to database" ] [ span [ class "icon icon-folder" ] [] ]


pagenation : Int -> Int -> Int -> Html Msg
pagenation numPage numTotalPage numArticles =
  let
    prevPageButton = button [ class "btn btn-default", onClick GetPrevResultPage ] [ span [ class "icon icon-left" ] [] ]
    nextPageButton = button [ class "btn btn-default", onClick GetNextResultPage ] [ span [ class "icon icon-right" ] [] ]
    prevPageButtonDisabled = button [ class "btn btn-default gray" ] [ span [ class "icon icon-left" ] [] ]
    nextPageButtonDisabled = button [ class "btn btn-default gray" ] [ span [ class "icon icon-right" ] [] ]
    inputPage = input [ style [ ("margin-left", "10px"), ("line-height", "18px") ]
                      , type_ "text"
                      , placeholder "page", size 6, onInput GotoResultPage ] []

    parts =
      if numPage == 1 then
        [ prevPageButtonDisabled, nextPageButton, inputPage ]
      else if numPage == numTotalPage then
        [ prevPageButton, nextPageButtonDisabled, inputPage ]
      else if numArticles == 0 then
        [ prevPageButtonDisabled, nextPageButtonDisabled, inputPage ]
      else
        [ prevPageButton, nextPageButton, inputPage ]
  in
    div [ style [ ("margin-top", "5px") ] ] [ span [] parts ]

viewerIframe =
  iframe [ id "pdf-viewer", style [ ("width", "100%"), ("height", "100%") ], src "./pdfjs/web/viewer.html" ] []

viewerContainer =
  div [ id "pdf-viewer-container" ] [ viewerIframe ]

searchWindow =
  span [] [ input [ type_ "text", placeholder "Search", onInput SendSearch ] []
  , span [ style [ ("font-size", "15pt") ] ] [ text " " ]
  , span [ class "icon icon-search", style [ ("vertical-align", "middle"), ("font-size", "15pt") ] ] []
  ]
