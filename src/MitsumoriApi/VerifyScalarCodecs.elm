-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module MitsumoriApi.VerifyScalarCodecs exposing (..)

{-
   This file is intended to be used to ensure that custom scalar decoder
   files are valid. It is compiled using `elm make` by the CLI.
-}

import MitsumoriApi.Scalar
import ScalarCodecs


verify : MitsumoriApi.Scalar.Codecs ScalarCodecs.BigInt ScalarCodecs.Cursor ScalarCodecs.Date ScalarCodecs.Datetime ScalarCodecs.Id ScalarCodecs.Json ScalarCodecs.Time ScalarCodecs.Uuid
verify =
    ScalarCodecs.codecs
