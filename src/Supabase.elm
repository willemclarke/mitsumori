module Supabase exposing (..)

import Http
import Json.Encode as JE
import RemoteData exposing (WebData)
import Url exposing (Protocol(..))
import User exposing (User)


type alias HttpInfo =
    { apiUrl : String
    , apiKey : String
    }


encodeUser : { email : String, username : String, password : String } -> JE.Value
encodeUser { email, username, password } =
    JE.object
        [ ( "email", JE.string email )
        , ( "username", JE.string username )
        , ( "password", JE.string password )
        ]


signUp : HttpInfo -> { email : String, username : String, password : String } -> (WebData User -> msg) -> Cmd msg
signUp { apiUrl, apiKey } user toMsg =
    Http.request
        { method = "POST"
        , body = Http.jsonBody <| encodeUser user
        , url = apiUrl ++ "/auth/v1/signup"
        , headers = [ Http.header "Authorization" apiKey ]
        , expect = Http.expectJson (RemoteData.fromResult >> toMsg) User.decoder
        , timeout = Nothing
        , tracker = Nothing
        }
