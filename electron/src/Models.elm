module Models exposing (..)

type alias Model =
  { currentQuery: String,
    numResultPage: Int,
    numTotalPage: Int,
    numArticles: Int,
    searchResult: SearchResult,
    indexResult: IndexResult,
    serverMessage: String,
    viewMode: ViewMode
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
    created_at: String
  }