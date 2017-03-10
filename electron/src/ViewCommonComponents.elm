module ViewCommonComponents exposing (..)

import Html exposing (Html, program, text, button, h1, h2, div, input, a, span, p, header, iframe, nav)
import Html.Attributes exposing (class, id, type_, placeholder, value, href, style, src, title, size)
import Html.Events exposing (onClick, onInput)

import Models exposing (Model)
import Messages exposing (Msg(..))
import Translation exposing (Language(..), TranslationId(..), translate)

toolbarHeader : Model -> Html Msg
toolbarHeader model =
  header [ class "toolbar toolbar-header" ] [ toolbarActions model ]

toolbarActions : Model -> Html Msg
toolbarActions model =
  div [ class "toolbar-actions" ] [ div [ class "btn-group" ] [ searchWindow model ], toolButtons model ]

toolButtons : Model -> Html Msg
toolButtons model =
  div [ class "btn-group" ] [ showIndexButton model, addFileButton model ]

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

viewerIframe =
  iframe [ id "pdf-viewer", style [ ("width", "100%"), ("height", "100%") ], src "./pdfjs/web/viewer.html" ] []

viewerContainer =
  div [ id "pdf-viewer-container" ] [ viewerIframe ]

searchWindow : Model -> Html Msg
searchWindow model =
  span
    []
    [ input
        [ type_ "text"
        , placeholder <| translate model.currentLanguage I18n_Search
        , onInput SendSearch
        , value model.currentQuery
        ]
        []
    , span [ style [ ("font-size", "15pt") ] ] [ text " " ]
    , span [ class "icon icon-search", style [ ("vertical-align", "middle"), ("font-size", "15pt") ] ] []
    ]
