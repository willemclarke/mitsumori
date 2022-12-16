-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module MitsumoriApi.Object.Quotes exposing (..)

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


{-| Globally Unique Record Identifier
-}
nodeId : SelectionSet ScalarCodecs.Id MitsumoriApi.Object.Quotes
nodeId =
    Object.selectionForField "ScalarCodecs.Id" "nodeId" [] (ScalarCodecs.codecs |> MitsumoriApi.Scalar.unwrapCodecs |> .codecId |> .decoder)


id : SelectionSet ScalarCodecs.Uuid MitsumoriApi.Object.Quotes
id =
    Object.selectionForField "ScalarCodecs.Uuid" "id" [] (ScalarCodecs.codecs |> MitsumoriApi.Scalar.unwrapCodecs |> .codecUuid |> .decoder)


quote_text : SelectionSet String MitsumoriApi.Object.Quotes
quote_text =
    Object.selectionForField "String" "quote_text" [] Decode.string


quote_author : SelectionSet String MitsumoriApi.Object.Quotes
quote_author =
    Object.selectionForField "String" "quote_author" [] Decode.string


user_id : SelectionSet ScalarCodecs.Uuid MitsumoriApi.Object.Quotes
user_id =
    Object.selectionForField "ScalarCodecs.Uuid" "user_id" [] (ScalarCodecs.codecs |> MitsumoriApi.Scalar.unwrapCodecs |> .codecUuid |> .decoder)


created_at : SelectionSet ScalarCodecs.Datetime MitsumoriApi.Object.Quotes
created_at =
    Object.selectionForField "ScalarCodecs.Datetime" "created_at" [] (ScalarCodecs.codecs |> MitsumoriApi.Scalar.unwrapCodecs |> .codecDatetime |> .decoder)


quote_reference : SelectionSet (Maybe String) MitsumoriApi.Object.Quotes
quote_reference =
    Object.selectionForField "(Maybe String)" "quote_reference" [] (Decode.string |> Decode.nullable)


type alias QuoteTagsCollectionOptionalArguments =
    { first : OptionalArgument Int
    , last : OptionalArgument Int
    , before : OptionalArgument ScalarCodecs.Cursor
    , after : OptionalArgument ScalarCodecs.Cursor
    , filter : OptionalArgument MitsumoriApi.InputObject.Quote_tagsFilter
    , orderBy : OptionalArgument (List MitsumoriApi.InputObject.Quote_tagsOrderBy)
    }


{-|

  - first - Query the first `n` records in the collection
  - last - Query the last `n` records in the collection
  - before - Query values in the collection before the provided cursor
  - after - Query values in the collection after the provided cursor
  - filter - Filters to apply to the results set when querying from the collection
  - orderBy - Sort order to apply to the collection

-}
quote_tagsCollection :
    (QuoteTagsCollectionOptionalArguments -> QuoteTagsCollectionOptionalArguments)
    -> SelectionSet decodesTo MitsumoriApi.Object.Quote_tagsConnection
    -> SelectionSet (Maybe decodesTo) MitsumoriApi.Object.Quotes
quote_tagsCollection fillInOptionals____ object____ =
    let
        filledInOptionals____ =
            fillInOptionals____ { first = Absent, last = Absent, before = Absent, after = Absent, filter = Absent, orderBy = Absent }

        optionalArgs____ =
            [ Argument.optional "first" filledInOptionals____.first Encode.int, Argument.optional "last" filledInOptionals____.last Encode.int, Argument.optional "before" filledInOptionals____.before (ScalarCodecs.codecs |> MitsumoriApi.Scalar.unwrapEncoder .codecCursor), Argument.optional "after" filledInOptionals____.after (ScalarCodecs.codecs |> MitsumoriApi.Scalar.unwrapEncoder .codecCursor), Argument.optional "filter" filledInOptionals____.filter MitsumoriApi.InputObject.encodeQuote_tagsFilter, Argument.optional "orderBy" filledInOptionals____.orderBy (MitsumoriApi.InputObject.encodeQuote_tagsOrderBy |> Encode.list) ]
                |> List.filterMap Basics.identity
    in
    Object.selectionForCompositeField "quote_tagsCollection" optionalArgs____ object____ (Basics.identity >> Decode.nullable)
