module Models exposing (..)

type alias Model =
  { currentQuery: String,
    numResultPage: Int,
    numTotalPage: Int,
    numArticles: Int,
    numPreviousArticles: Int, -- to detect file addition
    numAddedArticles: Int,
    sortField: String,
    reverse: Int, -- sort order, reverse if 1
    searchResult: SearchResult,
    indexResult: IndexResult,
    serverMessage: String,
    viewMode: ViewMode,
    indexClick: Int  -- workaround
  }

type ViewMode = SearchMode | IndexMode

type alias SearchResult =
  { rows: List SearchResultRow,
    n_hits: Int,
    total_pages: Int
  }

type alias SearchResultRow =
  { title: String,
    file_path: String,
    parent_file_path: String,
    page: Int,
    body: String
  }

type alias IndexResult =
  { rows: List IndexResultRow,
    n_docs: Int,
    total_pages: Int
  }

type alias IndexResultRow =
  { title: String,
    file_path: String,
    summary: String,
    created_at: String
  }
