module Utils exposing (..)

import Regex exposing (regex, replace, HowMany(..))

disableHyperlink : String -> String
disableHyperlink markdownString =
  let
    addTag str =
      replace All (regex (str ++ "://")) (\_ -> str ++ "<i></i>" ++ "://")
    addTagAll str =
      addTag "https" <| addTag "http" str
  in
    addTagAll markdownString
