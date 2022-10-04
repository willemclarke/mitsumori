port module Supabase exposing (Error, errorDecoder, session, sessionResponse, signIn, signInResponse, signOut, signUp, signUpResponse)

import Json.Decode as JD
import Json.Encode as JE


type alias Error =
    { message : String
    , status : Int
    }


errorDecoder : JD.Decoder Error
errorDecoder =
    JD.map2 Error
        (JD.field "message" JD.string)
        (JD.field "status" JD.int)


port signUp : JE.Value -> Cmd msg


port signUpResponse : (JE.Value -> msg) -> Sub msg


port signIn : JE.Value -> Cmd msg


port signInResponse : (JE.Value -> msg) -> Sub msg


port signOut : () -> Cmd msg


port session : () -> Cmd msg


port sessionResponse : (JE.Value -> msg) -> Sub msg
