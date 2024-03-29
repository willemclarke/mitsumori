module ScalarCodecs exposing (..)

import Iso8601
import Json.Decode as JD
import Json.Encode as JE
import MitsumoriApi.Scalar exposing (defaultCodecs)
import Time
import Uuid exposing (Uuid)



{- This module is responsible for mapping certain custom scalars (timestamptz, uuid), which are modelled as string
   to their respective elm types (timestamptz == Time, uuid = String)
-}


type alias Datetime =
    Time.Posix


type alias Uuid =
    String


type alias BigInt =
    MitsumoriApi.Scalar.BigInt


type alias Cursor =
    MitsumoriApi.Scalar.Cursor


type alias Date =
    MitsumoriApi.Scalar.Date


type alias Id =
    MitsumoriApi.Scalar.Id


type alias Json =
    MitsumoriApi.Scalar.Json


type alias Time =
    MitsumoriApi.Scalar.Time


codecs : MitsumoriApi.Scalar.Codecs BigInt Cursor Date Datetime Id Json Time Uuid
codecs =
    MitsumoriApi.Scalar.defineCodecs
        { codecBigInt = defaultCodecs.codecBigInt
        , codecCursor = defaultCodecs.codecCursor
        , codecDate = defaultCodecs.codecDate
        , codecDatetime =
            { encoder = \posixTime -> Iso8601.encode posixTime
            , decoder = Iso8601.decoder
            }
        , codecId = defaultCodecs.codecId
        , codecJson = defaultCodecs.codecJson
        , codecTime = defaultCodecs.codecTime
        , codecUuid =
            { encoder = \stringUuid -> JE.string stringUuid
            , decoder = JD.string
            }
        }
