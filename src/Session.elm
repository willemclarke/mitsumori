module Session exposing (..)

import Browser.Navigation as Nav
import Random exposing (Seed)


type alias Session =
    { key : Nav.Key
    , seed : Seed
    }
