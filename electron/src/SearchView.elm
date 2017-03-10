module SearchView exposing (..)

import Html exposing (Html, program, text, button, h1, h2, div, input, a, span, p, header, iframe, nav)
import Html.Attributes exposing (class, id, type_, placeholder, value, href, style, src, title, size)
import Html.Events exposing (onClick)
import Markdown
import Utils exposing (disableHyperlink)

import Models exposing (Model, SearchResultRow)
import Messages exposing (Msg(..))

import ViewCommonComponents exposing (toolbarHeader, viewerContainer, pagenation)

searchView : Model -> Html Msg
searchView model =
  let
    createComponent : SearchResultRow -> Html Msg
    createComponent row =
      let
        body = disableHyperlink row.body
        sBody = row.title ++ " (p" ++ toString row.page ++  "): " ++ body
      in
        div [] [ div [ class "search-result", onClick (OpenDocument (row.parent_file_path, row.page)) ] [ Markdown.toHtml [] sBody ]
        ]

    resultRows =
      List.map createComponent model.searchResult.rows

    resultDisplay =
      div [ class "result-container" ] resultRows

    resultSummary =
      let
        resPageStr = (toString model.numResultPage) ++ " of " ++ (toString model.numTotalPage)
        hitsStr = "(" ++ (toString model.numArticles) ++ " hits" ++ ")"

        summary =
          if model.numArticles == 0 then
            ""
          else
            resPageStr ++ " " ++ hitsStr
      in
        div [ class "result-summary" ] [ div [ style [ ("height", "15px") ] ] [ text summary ] ]

    sidebarContainer =
      div [ id "sidebar-container" ] [ div [ id "search" ]  [ pagenation model, resultSummary,  resultDisplay  ] ]

  in
    div []  [toolbarHeader model, sidebarContainer, viewerContainer model]
