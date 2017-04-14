module Models exposing (..)

import Window exposing (Size)
import Mouse exposing (Position)

type alias Model =
  { currentQuery: String
  , numResultPage: Int
  , numTotalPage: Int
  , numArticles: Int , numPreviousArticles: Int  -- to detect file addition
  , numAddedArticles: Int
  , sortField: String
  , reverse: Int  -- sort order, reverse if 1
  , searchResult: SearchResult
  , indexResult: IndexResult
  , serverMessage: ResultMessage
  , viewMode: ViewMode
  , indexClick: Int  -- workaround
  , itemDialog: Bool
  , itemRow: IndexResultRow
  , askDelete: Bool
  , pdfUrl: String
  , isUpdating: Bool
  , windowSize: Size
  , mousePosition: Position
  , drag: Maybe Drag
  , viewerContainerWidth: Int
  , sidebarWidth: Int
  , newTitle: String
  , config: Config
  }

type alias Config =
  { data_dir: String
  , pdf_dir: String
  , txt_dir: String
  , mode: String
  , locale: String
  }

type ViewMode = SearchMode | IndexMode

type alias SearchResult =
  { rows: List SearchResultRow
  , n_hits: Int
  , total_pages: Int
  }

type alias SearchResultRow =
  { title: String
  , file_path: String
  , parent_file_path: String
  , page: Int
  , body: String
  }

type alias IndexResult =
  { rows: List IndexResultRow
  , n_docs: Int
  , total_pages: Int
  }

type alias IndexResultRow =
  { title: String
  , file_path: String
  , summary: String
  , created_at: String
  , gid: String
  , published_at: String
  }

itemRowInit = IndexResultRow "" "" "" "" "" ""

type alias ResultMessage = String

type alias Drag =
  { start : Position
  , current : Position
  }
