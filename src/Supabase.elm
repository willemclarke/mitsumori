port module Supabase exposing (Key, session, sessionResponse, signIn, signUp, signUpResponse)

import Json.Encode as JE
import Route exposing (Route(..))


type alias Key =
    String


signUp : JE.Value -> Cmd msg
signUp =
    supabaseSignUp


session : () -> Cmd msg
session =
    supabaseSession


sessionResponse : (JE.Value -> msg) -> Sub msg
sessionResponse =
    subabaseSessionResponse


signUpResponse : (JE.Value -> msg) -> Sub msg
signUpResponse =
    supabaseSignUpResponse


signIn : JE.Value -> Cmd msg
signIn =
    supabaseSignIn


port supabaseSignUp : JE.Value -> Cmd msg


port supabaseSignIn : JE.Value -> Cmd msg


port supabaseSignUpResponse : (JE.Value -> msg) -> Sub msg


port supabaseSession : () -> Cmd msg


port subabaseSessionResponse : (JE.Value -> msg) -> Sub msg
