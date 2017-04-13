module IndexView exposing (..)

import Html exposing (Html, program, text, button, h1, h2, div, input, a, span, p, i, header, iframe, nav, pre, node, table, thead, tbody, tr, th, td, colgroup, col, form, label, textarea)
import Html.Attributes exposing (class, id, type_, placeholder, value, href, style, src, title, size, rel)
import Html.Events exposing (onClick, onInput)
import Markdown
import Dialog

import Models exposing (Model, IndexResultRow)
import Messages exposing (Msg(..))

import ViewCommonComponents exposing (toolbarHeader, viewerContainer, pagenation, getSideBarHeight, onMouseDown, onMouseDownFake)
import Translation exposing (Language(..), TranslationId(..), translate)


indexView : Model -> Html Msg
indexView model =
  let
    nPage = 1
    createComponent : IndexResultRow -> Html Msg
    createComponent row =
      let
        title = div [ class "search-result", onClick (OpenDocument (row.file_path, nPage)) ] [ text row.title ]
        config = div [ class "config" ] [ i [ class "fa fa-cogs", onClick (OpenItemDialog row) ] [] ]
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
        , style [ ("height",  getSideBarHeight model)
                , ("width", (toString model.mousePosition.x ) ++ "px")
                ]
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

    dialogBody =
      let
          title = translate model.currentLanguage I18n_title
          file_path = translate model.currentLanguage I18n_file_path
          summary = translate model.currentLanguage I18n_summary
          published_at = translate model.currentLanguage I18n_published_at
          created_at = translate model.currentLanguage I18n_created_at

          deleteConfirm =
            if model.askDelete == False then
              button
                [ onClick AskDeleteDocument, class "btn btn-secondary btn-sm ask-delete" ]
                [ text <| translate model.currentLanguage I18n_Ask_delete ]
            else
              button
                [ onClick DeleteDocument, class "btn btn-secondary btn-sm btn-danger ask-delete" ]
                [ text <| translate model.currentLanguage I18n_Confirm_delete ]
      in
        div
          []
          [
            form
              []
              [ div
                  [ class "form-group" ]
                  [ label [] [ text title]
                  , input [ class "form-control" , type_ "text" , value <| model.newTitle, onInput SetNewTitle ] []
                  ]
              , div
                  [ class "form-group" ]
                  [ label [] [ text summary]
                  , input [ class "form-control", type_ "text" , value <| model.itemRow.summary ] []
                  ]
              , div
                  [ class "form-group" ]
                  [ label [] [ text file_path]
                  , input [ class "form-control" , type_ "text" , value <| model.itemRow.file_path ] []
                  ]
              , div
                  [ class "form-group" ]
                  [ label [] [ text published_at]
                  , input [ class "form-control" , type_ "text" , value <| model.itemRow.published_at ] []
                  ]
              , div
                  [ class "form-group" ]
                  [ label [] [ text created_at]
                  , input [ class "form-control" , type_ "text" , value <| model.itemRow.created_at ] []
                  ]
              ]
            , deleteConfirm
          ]

    dialogView =
      Dialog.view
        (if model.itemDialog then
           Just
             { closeMessage = Nothing
             , containerClass = Just ""
             , header = Nothing
             , body = Just dialogBody
             , footer =
               Just
                 (div
                    []
                    [ button
                       [ class "btn btn-primary", onClick UpdateDocument ]
                       [ text <| translate model.currentLanguage I18n_Update ]
                    , button
                       [ class "btn" , onClick CancelUpdateDocument ]
                       [ text <| translate model.currentLanguage I18n_Quit ]
                    ]
                 )
             }
         else
           Nothing
        )
  in
    div
      []
      [ all
      , dialogView
      ]
