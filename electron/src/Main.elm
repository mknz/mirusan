module Main exposing (..)

import Html exposing (program)

import Messages exposing (Msg)
import Models exposing (Model, SearchResult, IndexResult)
import Update exposing (update)
import SearchView exposing (searchView)
import Ports exposing (subscriptions)


main : Program Never Model Msg
main =
  program
    { init = init
    , view = searchView
    , update = update
    , subscriptions = subscriptions
    }


-- Init

init : ( Model, Cmd Msg )
init =
  ({ currentQuery = ""
   , numResultPage = 1
   , numTotalPage = 0
   , numArticles = 0
   , searchResult = { rows = [], nHits = 0, totalPages = 0 }
   , indexResult = { rows = [], n_docs = 0, total_pages = 0 }
   , serverMessage = ""
   , viewMode = Models.SearchMode
   }
   , Cmd.none)

