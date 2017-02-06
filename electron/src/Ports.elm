port module Ports exposing (..)


import Models exposing (Model)
import Messages exposing (Msg(..))

port openNewFile : (String, Int) -> Cmd msg

-- SUBSCRIPTIONS
--port filesToAddDB : (List String -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [
    --filesToAddDB FilesToAddDB
  ]
