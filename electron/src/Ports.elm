port module Ports exposing (..)


import Models exposing (Model)
import Messages exposing (Msg(..))

import Time exposing (Time, second)


port openNewFile : (String, Int) -> Cmd msg
port pdfUrl : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
  let
    check =
      if model.isUpdating then
        Time.every (2 * second) CheckProgress  -- Check state every two seconds
      else
        Sub.none
  in
    Sub.batch
    [ pdfUrl PdfUrl
    , check
    ]
