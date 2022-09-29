port module Supabase exposing (session, sessionResponse, signIn, signInResponse, signOut, signUp, signUpResponse)

import Json.Encode as JE


signUp : JE.Value -> Cmd msg
signUp =
    supabaseSignUp


signUpResponse : (JE.Value -> msg) -> Sub msg
signUpResponse =
    supabaseSignUpResponse


signIn : JE.Value -> Cmd msg
signIn =
    supabaseSignIn


signInResponse : (JE.Value -> msg) -> Sub msg
signInResponse =
    supabaseSignInResponse


signOut : () -> Cmd msg
signOut =
    subabaseSignOut


session : () -> Cmd msg
session =
    supabaseSession


sessionResponse : (JE.Value -> msg) -> Sub msg
sessionResponse =
    subabaseSessionResponse


port supabaseSignUp : JE.Value -> Cmd msg


port supabaseSignUpResponse : (JE.Value -> msg) -> Sub msg


port supabaseSignIn : JE.Value -> Cmd msg


port supabaseSignInResponse : (JE.Value -> msg) -> Sub msg


port subabaseSignOut : () -> Cmd msg


port supabaseSession : () -> Cmd msg


port subabaseSessionResponse : (JE.Value -> msg) -> Sub msg
