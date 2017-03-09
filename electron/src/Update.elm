module Update exposing (..)

import Json.Encode
import Electron.IpcRenderer as IPC exposing (on, send)

import Messages exposing (Msg(..))
import Models exposing (Model, ViewMode(..), SearchResult, IndexResult)
import Search exposing (search, getIndex, deleteDocument)
import Ports exposing (openNewFile)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    setPage nPage =
      if model.numTotalPage == 1 then
        ( model, Cmd.none )
      else if model.numResultPage <= model.numTotalPage then
        case model.viewMode of
          SearchMode ->
            ( { model | numResultPage = nPage }, search model.currentQuery nPage model.sortField model.reverse )
          IndexMode ->
            ( { model | numResultPage = nPage }, getIndex model.sortField nPage model.reverse)
      else  -- last page
        ( model , Cmd.none )

  in
    case msg of
      SendSearch query ->
        ( { model | currentQuery = query, viewMode = Models.SearchMode }, search query model.numResultPage model.sortField model.reverse )

      NewSearchResult (Ok res) ->
        ( { model | searchResult = res, numTotalPage = res.total_pages, numArticles = res.n_hits, serverMessage = "" }, Cmd.none )

      NewSearchResult (Err _) ->
        ( { model | numResultPage = 1, numTotalPage = 0, numArticles = 0, searchResult = { rows = [], n_hits = 0, total_pages = 0 } }, Cmd.none )

      ShowIndex ->
        ( { model | currentQuery = "", viewMode = Models.IndexMode }, getIndex model.sortField model.numResultPage model.reverse)

      GotoSearchMode ->
        ( { model | numResultPage = 1, numTotalPage = 0, numArticles = 0, currentQuery = "", viewMode = Models.SearchMode, searchResult = { rows = [], n_hits = 0, total_pages = 0 }}, Cmd.none )

      NewIndexResult (Ok res) ->
        ( { model | indexResult = res, numTotalPage = res.total_pages, numArticles = res.n_docs, numAddedArticles = res.n_docs - model.numPreviousArticles, numPreviousArticles = res.n_docs, indexClick = model.indexClick + 1 }, Cmd.none )

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
                    search model.currentQuery nPage model.sortField model.reverse
                  IndexMode ->
                    getIndex model.sortField nPage model.reverse
            in
              if n < 1 then
              -- Go to first page
                ( { model | numResultPage = 1 }, action 1 )
              else if n >= 1 && n <= model.numTotalPage then
              -- Go to specified page
                ( { model | numResultPage = n }, action n )
              else
              -- Go to last page
                ( { model | numResultPage = model.numTotalPage }, action model.numTotalPage )

          (Err str) ->
            ( model , Cmd.none )

      OpenDocument (filePath, numPage) ->
        ( model, openNewFile (filePath, numPage) )

      AddFilesToDB ->
      -- send request to electron main process
        ( model, IPC.send "pdf-extract-request-main" Json.Encode.null)

      AskDeleteDocument gid ->
        ( { model | deleteDialog = True, deleteGid = gid }, Cmd.none )

      DeleteDocument ->
      -- Delete document (pdf + txt) using gid
        ( model, deleteDocument model.deleteGid )

      CancelDeleteDocument ->
        ( { model | deleteDialog = False, deleteGid = "" }, Cmd.none )

      DeleteResult (Ok res) ->
        ( { model | deleteDialog = False, deleteGid = "", serverMessage = res }, Cmd.none )

      DeleteResult (Err _) ->
        ( { model | deleteDialog = False, deleteGid = "", serverMessage = "" }, Cmd.none )
