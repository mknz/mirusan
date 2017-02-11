module IndexView exposing (..)

import Html exposing (Html, program, text, button, h1, h2, div, input, a, span, p, header, iframe, nav, pre)
import Html.Attributes exposing (class, id, type_, placeholder, value, href, style, src, title, size)
import Html.Events exposing (onClick)
import Markdown

import Models exposing (Model)
import Messages exposing (Msg(..))

import ViewCommonComponents exposing (toolbarHeader, viewerContainer, pagenation)

indexView : Model -> Html Msg
indexView model =
  let
    nPage = 1
    createComponent row =
      let
        title = div [ class "search-result", onClick (OpenDocument (row.file_path, nPage)) ] [ text row.title ]
        summary = div [] [ Markdown.toHtml [] row.summary ]
      in
        div [] [ title, summary ]

    resultDisplay =
      List.map createComponent model.indexResult.rows

    resultSummary =
      let
        resPageStr = (toString model.numResultPage) ++ " of " ++ (toString model.numTotalPage)
        hitsStr = "(" ++ (toString model.numArticles) ++ " documents" ++ ")"

        summary =
          if model.numArticles == 0 then
            ""
          else
            resPageStr ++ " " ++ hitsStr

        addedMessage =
        if model.indexClick <= 1 then
          -- do not display at boot
          div [] []
        else if model.numAddedArticles > 0 then
          div [ class "notification" ] [ text <| (toString model.numAddedArticles) ++ " new documents." ]
        else
          div [] []

      in
        div [] [ div [ style [ ("height", "15px") ] ] [ text summary ], addedMessage ]

    sidebarContainer =
      div [ id "sidebar-container" ] [ div [ id "search" ]  ( List.append [ pagenation model, resultSummary ] resultDisplay )  ]

  in
    div []  [toolbarHeader model, sidebarContainer, viewerContainer]
