module IndexView exposing (..)

import Html exposing (Html, program, text, button, h1, h2, div, input, a, span, p, i, header, iframe, nav, pre, node)
import Html.Attributes exposing (class, id, type_, placeholder, value, href, style, src, title, size, rel)
import Html.Events exposing (onClick)
import Markdown
import Dialog

import Models exposing (Model, IndexResultRow)
import Messages exposing (Msg(..))

import ViewCommonComponents exposing (toolbarHeader, viewerContainer, pagenation, getSideBarHeight)
import Translation exposing (Language(..), TranslationId(..), translate)


indexView : Model -> Html Msg
indexView model =
  let
    nPage = 1
    createComponent : IndexResultRow -> Html Msg
    createComponent row =
      let
        title = div [ class "search-result", onClick (OpenDocument (row.file_path, nPage)) ] [ text row.title ]
        config = div [ class "config" ] [ i [ class "fa fa-trash-o", onClick (AskDeleteDocument row.gid) ] [] ]
        container = div [ class "index-title-container" ] [ title, config ]
        summary = div [ class "summary" ] [ Markdown.toHtml [] row.summary ]
      in
        div [ class "index-component-container" ] [ container, summary ]

    resultRows =
      List.map createComponent model.indexResult.rows

    resultDisplay =
        div [ class "result-container" ] resultRows

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
        div
          [ class "result-summary" ]
          [ div
              [ style [ ("height", "15px") ] ]
              [ text summary ]
              , addedMessage
          ]

    sidebarContainer =
      div
        [ id "sidebar-container"
        , style [ ("height",  getSideBarHeight model) ]
        ]
        [ div
            [ id "search" ]
            [ pagenation model, resultSummary, resultDisplay ]
        ]

    all =
      div
        []
        [ toolbarHeader model
        , sidebarContainer
        , viewerContainer model
        ]

  in
    div
      []
      [ all
      , Dialog.view
          (if model.deleteDialog then
             Just
               { closeMessage = Nothing
               , containerClass = Just ""
               , header = Nothing
               , body = Just (p [] [text <| translate model.currentLanguage I18n_Ask_delete ])
               , footer =
                 Just
                   (div
                      []
                      [ button
                         [ class "btn btn-primary" , onClick DeleteDocument ]
                         [ text "Yes" ]
                      , button
                         [ class "btn" , onClick CancelDeleteDocument ]
                         [ text "No" ]
                      ]
                   )
               }
           else
             Nothing
          )
      ]
