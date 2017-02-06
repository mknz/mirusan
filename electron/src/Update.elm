module Update exposing (..)

import Json.Encode
import Electron.IpcRenderer as IPC exposing (on, send)

import Messages exposing (Msg(..))
import Models exposing (Model, SearchResult, IndexResult)
import Search exposing (search, getIndex)
import Ports exposing (openNewFile)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SendSearch query ->
      ( { model | currentQuery = query }, search query model.numResultPage )

    NewSearchResult (Ok res) ->
      ( { model | searchResult = res }, Cmd.none )

    NewSearchResult (Err _) ->
      ( { model | numResultPage = 1, searchResult = { rows = [], nHits = 0, totalPages = 0 } }, Cmd.none )

    GetNextResultPage ->
    -- pagenation
      let
        nPage = model.numResultPage + 1
      in
        if model.numResultPage < model.searchResult.totalPages then
          ( { model | numResultPage = nPage }, search model.currentQuery nPage )
        else  -- last page
          ( model , Cmd.none )

    GetPrevResultPage ->
    -- pagenation
      let
        nPage = model.numResultPage - 1
      in
        if model.numResultPage > 1 then
          ( { model | numResultPage = nPage }, search model.currentQuery nPage )
        else  -- last page
          ( model , Cmd.none )

    GotoResultPage inputStr ->
      case String.toInt inputStr of
        (Ok n) ->
          if n < 1 then
          -- Go to first page
            ( { model | numResultPage = 1 }, search model.currentQuery 1 )
          else if n >= 1 && n <= model.searchResult.totalPages then
          -- Go to specified page
            ( { model | numResultPage = n }, search model.currentQuery n )
          else
          -- Go to last page
            ( { model | numResultPage = model.searchResult.totalPages }, search model.currentQuery model.searchResult.totalPages )

        (Err str) ->
          ( model , Cmd.none )

    OpenDocument (fileName, numPage) ->
      ( model, openNewFile (fileName, numPage) )

    AddFilesToDB ->
    -- send request to electron main process
      ( model, IPC.send "pdf-extract-request-main" Json.Encode.null)

    GetIndex ->
      ( { model | currentQuery = "" }, getIndex "created_at" model.numResultPage )

    NewIndexResult (Ok res) ->
      ( { model | indexResult = res }, Cmd.none )

    NewIndexResult (Err _) ->
      ( { model | numResultPage = 1, indexResult = { rows = [], n_docs = 0, total_pages = 0 } }, Cmd.none )

