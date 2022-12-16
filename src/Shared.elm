module Shared exposing (Shared, SharedUpdate(..), SupabaseFlags, stepSeed, update)

import Browser.Navigation as Nav
import Components.Toast exposing (ToastType)
import Random exposing (Seed)
import Url
import User exposing (User)
import Uuid



{- This represents a piece of state which is common throughout the whole application
   and can be used/updated by submodules
-}


type alias Shared =
    { key : Nav.Key
    , user : User
    , seed : Seed
    , supabase : SupabaseFlags
    , toasts : List ( ToastType, Uuid.Uuid )
    }


type alias SupabaseFlags =
    { supabaseUrl : String
    , supabaseKey : String
    }


type SharedUpdate
    = NoUpdate
    | UpdateUser User
    | UpdateSupabase SupabaseFlags
    | ShowToast ToastType
    | CloseToast Uuid.Uuid
    | StepSeed


update : Shared -> SharedUpdate -> Shared
update shared sharedUpdate =
    case sharedUpdate of
        UpdateUser user ->
            { shared | user = user }

        UpdateSupabase supabaseFlags ->
            { shared | supabase = supabaseFlags }

        ShowToast toastType ->
            { shared | toasts = ( toastType, generateUuid shared.seed ) :: shared.toasts, seed = stepSeed shared.seed }

        CloseToast toastId ->
            { shared | toasts = List.filter (\( _, uuid_ ) -> uuid_ /= toastId) shared.toasts }

        StepSeed ->
            { shared | seed = stepSeed shared.seed }

        NoUpdate ->
            shared


generateUuid : Seed -> Uuid.Uuid
generateUuid seed =
    Tuple.first <| Random.step Uuid.uuidGenerator seed


stepSeed : Seed -> Seed
stepSeed =
    Tuple.second << Random.step (Random.int Random.minInt Random.maxInt)
