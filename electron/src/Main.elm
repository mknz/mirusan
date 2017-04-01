module Main exposing (..)

import Html exposing (program)

import Messages exposing (Msg)
import Models exposing (Model, IndexResult, SearchResult)
import Update exposing (update)
import View exposing (view)
import Ports exposing (subscriptions)
import Search exposing (search, getIndex)
import Translation exposing (Language(..))

main : Program Never Model Msg
main =
  program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- Init

init : ( Model, Cmd Msg )
init =
  let
    initSortField = "published_at"
    initPage = 1
    sortOrder = 0
  in
  ({ currentQuery = ""
   , numResultPage = initPage
   , numTotalPage = 0
   , numArticles = 0
   , numPreviousArticles = 0
   , numAddedArticles = 0
   , sortField = initSortField
   , reverse = sortOrder
   , searchResult = { rows = [], n_hits = 0, total_pages = 0 }
   , indexResult = { rows = [], n_docs = 0, total_pages = 0 }
   , serverMessage = ""
   , viewMode = Models.IndexMode
   , indexClick = 0
   , currentLanguage = English
   , deleteDialog = False
   , deleteGid = ""
   , pdfUrl = "./pdfjs/web/viewer.html"
   , isUpdating = False
   }
   , getIndex initSortField initPage sortOrder)

