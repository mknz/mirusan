module Update exposing (..)

import Json.Encode
import Electron.IpcRenderer as IPC exposing (on, send)
import Window
import Mouse exposing (Position)

import Messages exposing (Msg(..))
import Models exposing (Model, ViewMode(..), SearchResult, IndexResult, Drag)
import Search exposing (search, getIndex, deleteDocument, getProgress)
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
        ( { model | numResultPage = 1, numTotalPage = 0, numArticles = 0, viewMode = Models.SearchMode, searchResult = { rows = [], n_hits = 0, total_pages = 0 }}, Cmd.none )

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
        ( { model | isUpdating = True }, IPC.send "pdf-extract-request-main" Json.Encode.null)

      AskDeleteDocument gid ->
        ( { model | deleteDialog = True, deleteGid = gid }, Cmd.none )

      DeleteDocument ->
      -- Delete document (pdf + txt) using gid
        ( model, deleteDocument model.deleteGid )

      CancelDeleteDocument ->
        ( { model | deleteDialog = False, deleteGid = "" }, Cmd.none )

      DeleteResult (Ok res) ->
        ( { model | deleteDialog = False, deleteGid = "", serverMessage = "" }
        , getIndex model.sortField model.numResultPage model.reverse
        )

      DeleteResult (Err _) ->
        ( { model | deleteDialog = False, deleteGid = "", serverMessage = "" }, Cmd.none )

      PdfUrl url ->
        ( { model | pdfUrl = url }, Cmd.none )

      CheckProgress time ->
        ( model, getProgress ) -- time is dummy

      GetProgress (Ok res) ->
        if res == "Finished" then
          ( { model | serverMessage = "", isUpdating = False }, IPC.send "delete-tmpfile" Json.Encode.null )
        else
          ( { model | serverMessage = res }, Cmd.none )

      GetProgress (Err _) ->
        ( { model | serverMessage = "" }, Cmd.none )

      CheckWindowSize size ->
        ( { model | windowSize = size }, Cmd.none )

      DragStart pos ->
        ( { model | mousePosition = pos, drag = Just (Drag pos pos) }, Cmd.none )
      DragAt pos ->
        let
          newMousePosition = getPosition model
          newSidebarWidth = newMousePosition.x
        in
          ( { model | mousePosition = pos
            , drag = (Maybe.map (\{start} -> Drag start pos) model.drag)
            , viewerContainerWidth = model.windowSize.width - newSidebarWidth
            , sidebarWidth = newSidebarWidth
            }, Cmd.none )

      DragEnd _ ->
        let
          newMousePosition = getPosition model
          newSidebarWidth = newMousePosition.x
        in
          ( { model | mousePosition = newMousePosition
              , drag = Nothing
              , viewerContainerWidth = model.windowSize.width - newSidebarWidth
              , sidebarWidth = newSidebarWidth
            }
            , Cmd.none )

      DragNothing _ ->
        ( model, Cmd.none )

getPosition : Model -> Position
getPosition model =
  case model.drag of
    Nothing ->
      model.mousePosition

    Just {start, current} ->
      Position
        (current.x)
        (current.y)
        --(model.mousePosition.x + current.x - start.x)
        --(model.mousePosition.y + current.y - start.y)
