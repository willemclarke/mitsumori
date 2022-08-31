port module Ports exposing (get, set)

import Json.Encode as JE


type alias Key =
    String


get : Key -> Cmd msg
get =
    localStorageGet


set : ( Key, JE.Value ) -> Cmd msg
set =
    localStorageSet


port localStorageSet : ( Key, JE.Value ) -> Cmd msg


port localStorageGet : Key -> Cmd msg
