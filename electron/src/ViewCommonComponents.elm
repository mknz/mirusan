module ViewCommonComponents exposing (..)

import Html exposing (Html, Attribute, program, text, button, h1, h2, div, input, a, span, p, header, iframe, nav)
import Html.Attributes exposing (class, id, type_, placeholder, value, href, style, src, title, size, autofocus, disabled)
import Html.Events exposing (onClick, onInput, onFocus, on)
import List exposing (append)
import Mouse
import Json.Decode as Decode

import Models exposing (Model, ViewMode(..))
import Messages exposing (Msg(..))
import Translation exposing (Language(..), TranslationId(..), translate)

toolbarHeader : Model -> Html Msg
toolbarHeader model =
  header [ class "toolbar toolbar-header" ] [ toolbarActions model ]

toolbarActions : Model -> Html Msg
toolbarActions model =
  case model.viewMode of
    SearchMode ->
      div [ class "toolbar-actions" ] [ div [ class "btn-group" ] [ searchWindow model ], toolButtons model ]
    IndexMode ->
      div [ class "toolbar-actions" ] [ div [ class "btn-group" ] [ searchWindow model ], toolButtons model ]

toolButtons : Model -> Html Msg
toolButtons model =
  div [ class "btn-group" ] [ showIndexButton model, addFileButton model, span [ class "server-message" ] [ text model.serverMessage ] ]

showIndexButton : Model -> Html Msg
showIndexButton model =
  case model.viewMode of
    Models.IndexMode ->
      button [ class "btn active btn-large btn-default", onClick GotoSearchMode, title <| translate model.currentLanguage I18n_Go_to_search ] [ span [ class "icon icon-list" ] [] ]
    Models.SearchMode ->
      button [ class "btn btn-large btn-default", onClick ShowIndex, title <| translate model.currentLanguage I18n_Show_index ] [ span [ class "icon icon-list" ] [] ]

addFileButton : Model -> Html Msg
addFileButton model =
  button [ class "btn btn-large btn-default", onClick AddFilesToDB, title <| translate model.currentLanguage I18n_Add_files_to_database ] [ span [ class "icon icon-folder" ] [] ]


pagenation : Model -> Html Msg
pagenation model =
  let
    prevPageButton = button [ class "btn btn-default", onClick GetPrevResultPage ] [ span [ class "icon icon-left" ] [] ]
    nextPageButton = button [ class "btn btn-default", onClick GetNextResultPage ] [ span [ class "icon icon-right" ] [] ]
    prevPageButtonDisabled = button [ class "btn btn-default gray" ] [ span [ class "icon icon-left" ] [] ]
    nextPageButtonDisabled = button [ class "btn btn-default gray" ] [ span [ class "icon icon-right" ] [] ]
    inputPage = input [ style [ ("margin-left", "10px"), ("line-height", "18px") ]
                      , type_ "text"
                      , placeholder <| translate model.currentLanguage I18n_page, size 6, onInput GotoResultPage ] []

    parts =
      if model.numResultPage == 1 then
        [ prevPageButtonDisabled, nextPageButton, inputPage ]
      else if model.numResultPage == model.numTotalPage then
        [ prevPageButton, nextPageButtonDisabled, inputPage ]
      else if model.numArticles == 0 then
        [ prevPageButtonDisabled, nextPageButtonDisabled, inputPage ]
      else
        [ prevPageButton, nextPageButton, inputPage ]
  in
    div [ style [ ("margin-top", "5px") ] ] [ span [] parts ]


-- pdf viewer

-- Always display gray background in Elm.
-- PDF load is triggered only in renderer.js
-- This is a workaround, to prevent unwanted reload of pdf-viewer.

viewerIframe : Model -> Html Msg
viewerIframe model =
  iframe [ id "pdf-viewer", style [ ("background-color", "#888888"), ("width", "100%"), ("height", "100%"), ("overflow", "hidden") ] ] []

viewerContainer : Model -> Html Msg
viewerContainer model =
  div [ id "pdf-viewer-container"
      , style [ ("height", getSideBarHeight model)
              , ("width", (toString (model.windowSize.width - model.mousePosition.x)) ++ "px")
              ]
      ]
      [ viewerIframe model ]


-- search input window

searchWindow : Model -> Html Msg
searchWindow model =
  let
    attrs =
      [ type_ "text"
      , placeholder <| translate model.currentLanguage I18n_Search
      , onInput SendSearch
      , value model.currentQuery
      , autofocus True
      , onFocus GotoSearchMode
      ]
    indexAttrs = [ disabled True, class "search-window-inactive"]

    inputField =
      case model.viewMode of
        SearchMode ->
          input
            attrs
            []
        IndexMode ->
          input
            (append attrs indexAttrs)
            []
  in
    span
      []
      [ inputField
      , span [ style [ ("font-size", "15pt") ] ] [ text " " ]
      , span [ class "icon icon-search", style [ ("vertical-align", "middle"), ("font-size", "15pt") ] ] []
      ]

getSideBarHeight : Model -> String
getSideBarHeight model =
  let
    margin = 40  -- header's height
    sideBarHeight = model.windowSize.height - margin
  in
    (toString sideBarHeight) ++ "px"

onMouseDown : Attribute Msg
onMouseDown =
  on "mousedown" (Decode.map DragStart Mouse.position)
