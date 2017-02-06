module Models exposing (..)

type alias Model =
  { currentQuery: String,
    numResultPage: Int,
    searchResult: SearchResult,
    serverMessage: String,
    indexResult: IndexResult
  }

type alias SearchResult =
  { rows: List SearchResultRow,
    nHits: Int,
    totalPages: Int
  }

type alias SearchResultRow =
  { title: String,
    fileName: String,
    numPage: Int,
    body: String
  }

type alias IndexResult =
  { rows: List IndexResultRow,
    n_docs: Int,
    total_pages: Int
  }

type alias IndexResultRow =
  { title: String,
    document_file_name: String,
    created_at: String
  }
