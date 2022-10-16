-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module MitsumoriApi.Object.Quote_tagsInsertResponse exposing (..)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode
import MitsumoriApi.InputObject
import MitsumoriApi.Interface
import MitsumoriApi.Object
import MitsumoriApi.Scalar
import MitsumoriApi.Union
import ScalarCodecs


{-| Count of the records impacted by the mutation
-}
affectedCount : SelectionSet Int MitsumoriApi.Object.Quote_tagsInsertResponse
affectedCount =
    Object.selectionForField "Int" "affectedCount" [] Decode.int


{-| Array of records impacted by the mutation
-}
records :
    SelectionSet decodesTo MitsumoriApi.Object.Quote_tags
    -> SelectionSet (List decodesTo) MitsumoriApi.Object.Quote_tagsInsertResponse
records object____ =
    Object.selectionForCompositeField "records" [] object____ (Basics.identity >> Decode.list)
