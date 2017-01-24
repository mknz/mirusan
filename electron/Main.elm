port module Main exposing (..)

import Electron.IpcRenderer as IPC exposing (on, send)

import Html exposing (Html, program, text, button, h1, h2, div, input)
import Html.Attributes exposing (class, type_, placeholder)
import Html.Events exposing (onClick, onInput)
import Json.Encode
import Json.Decode exposing (int, string, float, nullable, map, map2, field, at, list, Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Http
import Debug


main =
  program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL


type alias Model =
  { currentTime: String,
    pdfFilename: String,
    searchResult: SearchResult
  }

type alias SearchResultRow =
  { fileName: String,
    body: String
  }

type alias SearchResult = List SearchResultRow

init : ( Model, Cmd Msg )
init =
  ({ currentTime = "None", pdfFilename = "", searchResult = [] }, Cmd.none)


type alias TimeRequest =
    { format : String
    }


encodeRequest : TimeRequest -> Json.Encode.Value
encodeRequest request =
    Json.Encode.object
      [ ( "format", Json.Encode.string request.format ) ]


type alias TimeResponse =
    { status : String
    , time : String
    }


decodeResponse : Decoder TimeResponse
decodeResponse =
    decode TimeResponse
        |> required "status" string
        |> required "time" string


-- UPDATE


type Msg
  = Send String
  | SetNewFile String
  | SendSearch String
  | NewSearchResult (Result Http.Error SearchResult)
  | OpenPdf

port openNewFile : String -> Cmd msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
      pdfFilename =
        case (List.head model.searchResult) of
          Nothing -> ""
          Just row -> row.fileName
  in
      case msg of
        Send format ->
          ( model, IPC.send "time-request" <| encodeRequest { format = format } )
        SetNewFile fileName ->
          ( { model | pdfFilename = fileName }, openNewFile fileName )
        SendSearch query ->
          ( model, search query )
        NewSearchResult (Ok res) ->
          ( { model | searchResult = res }, Cmd.none )
        NewSearchResult (Err _) ->
          ( model, Cmd.none )
        OpenPdf ->
          ( model, openNewFile ("../data/text/" ++ pdfFilename))


-- VIEW


view : Model -> Html Msg
view model =
  let
      pdfFilename =
        case (List.head model.searchResult) of
          Nothing -> ""
          Just row -> row.fileName

  in
      div []
        [ h1 [] [ text "PDF collection reader" ]
        , div [] [ text ("result: " ++ pdfFilename) ]
        , input [ type_ "text", placeholder "Filename", onInput SetNewFile ] []
        , input [ type_ "text", placeholder "Search", onInput SendSearch ] []
        , button [ class "btn btn-default btn-lg btn-block", onClick (OpenPdf) ] [ text "Open PDF" ]
        ]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [ --IPC.on "time-response" (map OnResponse decodeResponse)
    Sub.none
  ]


-- HTTP

search : String -> Cmd Msg
search query =
  let
      url =
        "http://localhost:8000/search?query=" ++ query
  in
      Http.send NewSearchResult (Http.get url searchResponseDecoder)


-- JSON decoders

rowDecoder =
  map2 SearchResultRow (field "file-name" string) (field "body" string)

searchResponseDecoder : Decoder SearchResult
searchResponseDecoder =
  at ["results"] <| list rowDecoder
