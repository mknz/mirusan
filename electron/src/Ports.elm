port module Ports exposing (..)


import Models exposing (Model)
import Messages exposing (Msg(..))


port openNewFile : (String, Int) -> Cmd msg
port pdfUrl : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [
    pdfUrl PdfUrl
  ]
