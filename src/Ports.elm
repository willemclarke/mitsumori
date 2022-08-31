port module Ports exposing (Key, getQuotes, getQuotesResponse, setQuote)

import Json.Encode as JE


type alias Key =
    String


getQuotes : Key -> Cmd msg
getQuotes =
    indexedDbGetQuotes


getQuotesResponse : (( Key, JE.Value ) -> msg) -> Sub msg
getQuotesResponse =
    indexedDbGetQuotesResponse


setQuote : ( Key, JE.Value ) -> Cmd msg
setQuote =
    indexedDbSetQuote


port indexedDbSetQuote : ( Key, JE.Value ) -> Cmd msg


port indexedDbGetQuotes : Key -> Cmd msg


port indexedDbGetQuotesResponse : (( Key, JE.Value ) -> msg) -> Sub msg
