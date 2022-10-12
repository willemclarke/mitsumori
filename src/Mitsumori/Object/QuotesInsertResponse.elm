-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Mitsumori.Object.QuotesInsertResponse exposing (..)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode
import Mitsumori.InputObject
import Mitsumori.Interface
import Mitsumori.Object
import Mitsumori.Scalar
import Mitsumori.ScalarCodecs
import Mitsumori.Union


{-| Count of the records impacted by the mutation
-}
affectedCount : SelectionSet Int Mitsumori.Object.QuotesInsertResponse
affectedCount =
    Object.selectionForField "Int" "affectedCount" [] Decode.int


{-| Array of records impacted by the mutation
-}
records :
    SelectionSet decodesTo Mitsumori.Object.Quotes
    -> SelectionSet (List decodesTo) Mitsumori.Object.QuotesInsertResponse
records object____ =
    Object.selectionForCompositeField "records" [] object____ (Basics.identity >> Decode.list)
