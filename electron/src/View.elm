module View exposing (..)

import Html exposing (Html)

import Models exposing (Model)
import Messages exposing (Msg(..))

import SearchView exposing (searchView)
import IndexView exposing (indexView)


view : Model -> Html Msg
view model =
  case model.viewMode of
    Models.SearchMode ->
      searchView model
    Models.IndexMode ->
      indexView model
