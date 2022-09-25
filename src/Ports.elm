port module Ports exposing (Key, getQuotes, getQuotesResponse, setQuote, supabaseSignIn, supabaseSignUp, supabaseSignUpResponse)

import Json.Encode as JE
import Route exposing (Route(..))


type alias Key =
    String


supabaseSignUp : JE.Value -> Cmd msg
supabaseSignUp =
    signUp


supabaseSignUpResponse : (JE.Value -> msg) -> Sub msg
supabaseSignUpResponse =
    signUpResponse


supabaseSignIn : JE.Value -> Cmd msg
supabaseSignIn =
    signIn


getQuotes : () -> Cmd msg
getQuotes =
    dataStoreGetQuotes


getQuotesResponse : (JE.Value -> msg) -> Sub msg
getQuotesResponse =
    dataStoreGetQuoteResponse


setQuote : JE.Value -> Cmd msg
setQuote =
    dataStoreSetQuote


port signUp : JE.Value -> Cmd msg


port signIn : JE.Value -> Cmd msg


port signUpResponse : (JE.Value -> msg) -> Sub msg


port dataStoreSetQuote : JE.Value -> Cmd msg


port dataStoreGetQuotes : () -> Cmd msg


port dataStoreGetQuoteResponse : (JE.Value -> msg) -> Sub msg
