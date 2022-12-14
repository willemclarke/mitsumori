-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module MitsumoriApi.Scalar exposing (BigInt(..), Codecs, Cursor(..), Date(..), Datetime(..), Id(..), Json(..), Time(..), Uuid(..), defaultCodecs, defineCodecs, unwrapCodecs, unwrapEncoder)

import Graphql.Codec exposing (Codec)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type BigInt
    = BigInt String


type Cursor
    = Cursor String


type Date
    = Date String


type Datetime
    = Datetime String


type Id
    = Id String


type Json
    = Json String


type Time
    = Time String


type Uuid
    = Uuid String


defineCodecs :
    { codecBigInt : Codec valueBigInt
    , codecCursor : Codec valueCursor
    , codecDate : Codec valueDate
    , codecDatetime : Codec valueDatetime
    , codecId : Codec valueId
    , codecJson : Codec valueJson
    , codecTime : Codec valueTime
    , codecUuid : Codec valueUuid
    }
    -> Codecs valueBigInt valueCursor valueDate valueDatetime valueId valueJson valueTime valueUuid
defineCodecs definitions =
    Codecs definitions


unwrapCodecs :
    Codecs valueBigInt valueCursor valueDate valueDatetime valueId valueJson valueTime valueUuid
    ->
        { codecBigInt : Codec valueBigInt
        , codecCursor : Codec valueCursor
        , codecDate : Codec valueDate
        , codecDatetime : Codec valueDatetime
        , codecId : Codec valueId
        , codecJson : Codec valueJson
        , codecTime : Codec valueTime
        , codecUuid : Codec valueUuid
        }
unwrapCodecs (Codecs unwrappedCodecs) =
    unwrappedCodecs


unwrapEncoder :
    (RawCodecs valueBigInt valueCursor valueDate valueDatetime valueId valueJson valueTime valueUuid -> Codec getterValue)
    -> Codecs valueBigInt valueCursor valueDate valueDatetime valueId valueJson valueTime valueUuid
    -> getterValue
    -> Graphql.Internal.Encode.Value
unwrapEncoder getter (Codecs unwrappedCodecs) =
    (unwrappedCodecs |> getter |> .encoder) >> Graphql.Internal.Encode.fromJson


type Codecs valueBigInt valueCursor valueDate valueDatetime valueId valueJson valueTime valueUuid
    = Codecs (RawCodecs valueBigInt valueCursor valueDate valueDatetime valueId valueJson valueTime valueUuid)


type alias RawCodecs valueBigInt valueCursor valueDate valueDatetime valueId valueJson valueTime valueUuid =
    { codecBigInt : Codec valueBigInt
    , codecCursor : Codec valueCursor
    , codecDate : Codec valueDate
    , codecDatetime : Codec valueDatetime
    , codecId : Codec valueId
    , codecJson : Codec valueJson
    , codecTime : Codec valueTime
    , codecUuid : Codec valueUuid
    }


defaultCodecs : RawCodecs BigInt Cursor Date Datetime Id Json Time Uuid
defaultCodecs =
    { codecBigInt =
        { encoder = \(BigInt raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map BigInt
        }
    , codecCursor =
        { encoder = \(Cursor raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Cursor
        }
    , codecDate =
        { encoder = \(Date raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Date
        }
    , codecDatetime =
        { encoder = \(Datetime raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Datetime
        }
    , codecId =
        { encoder = \(Id raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Id
        }
    , codecJson =
        { encoder = \(Json raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Json
        }
    , codecTime =
        { encoder = \(Time raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Time
        }
    , codecUuid =
        { encoder = \(Uuid raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Uuid
        }
    }
