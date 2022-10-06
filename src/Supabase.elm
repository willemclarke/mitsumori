port module Supabase exposing (Error, Quote, addQuote, addQuoteResponse, errorDecoder, getQuotes, quoteDecoder, session, sessionResponse, signIn, signInResponse, signOut, signUp, signUpResponse)

import Json.Decode as JD
import Json.Encode as JE


type alias Quote =
    { id : String
    , quote_text : String
    , quote_author : String
    , created_at : String
    , user_id : String
    }


type alias Error =
    { message : String
    , status : Int
    }


quoteDecoder : JD.Decoder Quote
quoteDecoder =
    JD.map5 Quote
        (JD.field "id" JD.string)
        (JD.field "quote_text" JD.string)
        (JD.field "quote_author" JD.string)
        (JD.field "created_at" JD.string)
        (JD.field "user_id" JD.string)


errorDecoder : JD.Decoder Error
errorDecoder =
    JD.map2 Error
        (JD.field "message" JD.string)
        (JD.field "status" JD.int)


port addQuote : JE.Value -> Cmd msg


port addQuoteResponse : (JE.Value -> msg) -> Sub msg


port getQuotes : String -> Cmd msg


port signUp : JE.Value -> Cmd msg


port signUpResponse : (JE.Value -> msg) -> Sub msg


port signIn : JE.Value -> Cmd msg


port signInResponse : (JE.Value -> msg) -> Sub msg


port signOut : () -> Cmd msg


port session : () -> Cmd msg


port sessionResponse : (JE.Value -> msg) -> Sub msg
