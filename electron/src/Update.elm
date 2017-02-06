module Update exposing (..)

import Json.Encode
import Electron.IpcRenderer as IPC exposing (on, send)

import Messages exposing (Msg(..))
import Models exposing (Model, ViewMode(..), SearchResult, IndexResult)
import Search exposing (search, getIndex)
import Ports exposing (openNewFile)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    setPage nPage =
      if model.numResultPage < model.numTotalPage then
        case model.viewMode of
          SearchMode ->
            ( { model | numResultPage = nPage }, search model.currentQuery nPage )
          IndexMode ->
            ( { model | numResultPage = nPage }, getIndex "created_at" nPage )
      else  -- last page
        ( model , Cmd.none )

  in
    case msg of
      SendSearch query ->
        ( { model | currentQuery = query }, search query model.numResultPage )

      NewSearchResult (Ok res) ->
        ( { model | searchResult = res, numResultPage = 1, numTotalPage = res.totalPages, numArticles = res.nHits, serverMessage = "" }, Cmd.none )

      NewSearchResult (Err _) ->
        ( { model | numResultPage = 1, numTotalPage = 0, numArticles = 0, searchResult = { rows = [], nHits = 0, totalPages = 0 } }, Cmd.none )

      GetIndex ->
        ( { model | currentQuery = "" }, getIndex "created_at" model.numResultPage )

      NewIndexResult (Ok res) ->
        ( { model | indexResult = res, numResultPage = 1, numTotalPage = res.total_pages, numArticles = res.n_docs, serverMessage = "" }, Cmd.none )

      NewIndexResult (Err _) ->
        ( { model | numResultPage = 1, numTotalPage = 0, numArticles = 0, indexResult = { rows = [], n_docs = 0, total_pages = 0 } }, Cmd.none )

      GetNextResultPage ->
        setPage <| model.numResultPage + 1

      GetPrevResultPage ->
        setPage <| model.numResultPage - 1

      GotoResultPage inputStr ->
        case String.toInt inputStr of
          (Ok n) ->
            let
              action nPage =
                case model.viewMode of
                  SearchMode ->
                    search model.currentQuery nPage
                  IndexMode ->
                    getIndex "created_at" nPage
            in
              if n < 1 then
              -- Go to first page
                ( { model | numResultPage = 1 }, action 1 )
              else if n >= 1 && n <= model.searchResult.totalPages then
              -- Go to specified page
                ( { model | numResultPage = n }, action n )
              else
              -- Go to last page
                ( { model | numResultPage = model.numTotalPage }, action model.numTotalPage )

          (Err str) ->
            ( model , Cmd.none )

      OpenDocument (fileName, numPage) ->
        ( model, openNewFile (fileName, numPage) )

      AddFilesToDB ->
      -- send request to electron main process
        ( model, IPC.send "pdf-extract-request-main" Json.Encode.null)

