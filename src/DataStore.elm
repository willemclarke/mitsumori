port module DataStore exposing (Key, getQuotes, getQuotesResponse, setQuote)

import Json.Encode as JE


type alias Key =
    String


getQuotes : Key -> Cmd msg
getQuotes =
    dataStoreGetQuotes


getQuotesResponse : (JE.Value -> msg) -> Sub msg
getQuotesResponse =
    dataStoreGetQuoteResponse


setQuote : JE.Value -> Cmd msg
setQuote =
    dataStoreSetQuote


port dataStoreSetQuote : JE.Value -> Cmd msg


port dataStoreGetQuotes : Key -> Cmd msg


port dataStoreGetQuoteResponse : (JE.Value -> msg) -> Sub msg
