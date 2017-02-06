module View exposing (..)

import Html exposing (Html, program, text, button, h1, h2, div, input, a, span, p, header, iframe, nav)
import Html.Attributes exposing (class, id, type_, placeholder, value, href, style, src, title, size)
import Html.Events exposing (onClick, onInput)

import Markdown

import Models exposing (Model)
import Messages exposing (Msg(..))


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
        button [ class "btn btn-large btn-default", onClick AddFilesToDB, title "Add files to database" ] [ span [ class "icon icon-folder" ] [] ]
      getIndexButton =
        button [ class "btn btn-large btn-default", onClick GetIndex, title "Get index" ] [ span [ class "icon icon-folder" ] [] ]

      toolButtons =
        div [ class "btn-group" ] [ addFileButton, getIndexButton ]

      toolbarActions =
        div [ class "toolbar-actions" ] [ div [ class "btn-group" ] [ searchWindow ], toolButtons, span [] [ text model.serverMessage ] ]

      searchResultSummary =
        let
          resPageStr = (toString model.numResultPage) ++ " page of " ++ (toString model.searchResult.totalPages)
          hitsStr = "(" ++ (toString model.searchResult.nHits) ++ " hits" ++ ")"

          summary =
            if model.searchResult.totalPages == 0 then
              ""
            else
              resPageStr ++ " " ++ hitsStr
        in
          div [] [ div [ style [ ("height", "15px") ] ] [ text summary ] ]

      pagenation =
        let
          prevPageButton = button [ class "btn btn-default", onClick GetPrevResultPage ] [ span [ class "icon icon-left" ] [] ]
          nextPageButton = button [ class "btn btn-default", onClick GetNextResultPage ] [ span [ class "icon icon-right" ] [] ]
          prevPageButtonDisabled = button [ class "btn btn-default gray" ] [ span [ class "icon icon-left" ] [] ]
          nextPageButtonDisabled = button [ class "btn btn-default gray" ] [ span [ class "icon icon-right" ] [] ]
          inputPage = input [ style [ ("margin-left", "10px"), ("line-height", "18px") ]
                            , type_ "text"
                            , placeholder "page", size 6, onInput GotoResultPage ] []

          parts =
            if model.numResultPage == 1 then
              [ prevPageButtonDisabled, nextPageButton, inputPage ]
            else if model.numResultPage == model.searchResult.totalPages then
              [ prevPageButton, nextPageButtonDisabled, inputPage ]
            else if model.searchResult.nHits == 0 then
              [ prevPageButtonDisabled, nextPageButtonDisabled, inputPage ]
            else
              [ prevPageButton, nextPageButton, inputPage ]
        in
          div [ style [ ("margin-top", "5px") ] ] [ span [] parts ]

      sidebarContainer =
        div [ id "sidebar-container" ] [ div [ id "search" ]  ( List.append [ pagenation, searchResultSummary ] searchResultDisplay )  ]

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
      --div []  [toolbarHeader, sidebarContainer, viewerContainer]
      div []  [toolbarHeader, div [] [text (toString model.indexResult.n_docs)], sidebarContainer, viewerContainer]
