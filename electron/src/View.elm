module View exposing (..)

import Html exposing (Html, div, text, i)
import Html.Attributes exposing (id, class, style)

import Models exposing (Model)
import Messages exposing (Msg(..))

import SearchView exposing (searchView)
import IndexView exposing (indexView)
import ViewCommonComponents exposing (onMouseDown)


view : Model -> Html Msg
view model =
  let
    container =
      case model.viewMode of
        Models.SearchMode ->
          searchView model
        Models.IndexMode ->
          indexView model

    screen =
      div
        [ id "screen" ]
        [ div
            [ id "dragger"
            , style
                [ ("left", (toString (model.sidebarWidth - 10)) ++ "px")
                , ("height", (toString model.windowSize.height) ++ "px")
                ]
            ]
            [ i [ onMouseDown, class "fa fa-circle" ][] ]
        ]
  in
    div
      []
      [ screen, container ]
