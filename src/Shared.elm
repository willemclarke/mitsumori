module Shared exposing (Shared, SharedUpdate(..), SupabaseFlags, update)

import Browser.Navigation as Nav
import Random exposing (Seed)
import Url
import User exposing (User)



{- This represents a piece of state which is common throughout the whole application
   and can be used/updated by submodules
-}


type alias Shared =
    { key : Nav.Key
    , url : Url.Url
    , user : User
    , seed : Seed
    , supabase : SupabaseFlags
    }


type alias SupabaseFlags =
    { supabaseUrl : String
    , supabaseKey : String
    }


type SharedUpdate
    = NoUpdate
    | UpdateUser User
    | UpdateSupabase SupabaseFlags


update : Shared -> SharedUpdate -> Shared
update shared sharedUpdate =
    case sharedUpdate of
        UpdateUser user ->
            { shared | user = user }

        UpdateSupabase supabaseFlags ->
            { shared | supabase = supabaseFlags }

        NoUpdate ->
            shared
