module Session exposing (..)

import Browser.Navigation as Nav
import Random exposing (Seed)
import User exposing (User)


type alias Session =
    { key : Nav.Key
    , user : User
    , seed : Seed
    , supabase : SupabaseFlags
    }


type alias SupabaseFlags =
    { supabaseUrl : String
    , supabaseKey : String
    }
