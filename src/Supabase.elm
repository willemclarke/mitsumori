port module Supabase exposing (Key, signIn, signUp, signUpResponse)

import Json.Encode as JE
import Route exposing (Route(..))


type alias Key =
    String


signUp : JE.Value -> Cmd msg
signUp =
    supabaseSignUp


signUpResponse : (JE.Value -> msg) -> Sub msg
signUpResponse =
    supabaseSignUpResponse


signIn : JE.Value -> Cmd msg
signIn =
    supabaseSignIn


port supabaseSignUp : JE.Value -> Cmd msg


port supabaseSignIn : JE.Value -> Cmd msg


port supabaseSignUpResponse : (JE.Value -> msg) -> Sub msg
