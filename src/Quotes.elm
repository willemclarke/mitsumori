module Quotes exposing (Quote, Response, makeRequest)

import Graphql.Http
import Graphql.Operation exposing (RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import MitsumoriApi.Object
import MitsumoriApi.Object.Quotes as Quotes
import MitsumoriApi.Object.QuotesConnection as QuotesConnection
import MitsumoriApi.Object.QuotesEdge as QuotesEdge
import MitsumoriApi.Query as Query
import MitsumoriApi.Scalar
import RemoteData exposing (RemoteData)
import Shared exposing (Shared)



{- This module is to handle all GraphQL queries/mutations pertaining to Quotes -}


type alias Quote =
    { id : String
    , quote_text : String
    , quote_author : String
    , created_at : String
    , user_id : String
    , quote_reference : Maybe String
    }


type alias Response =
    { quotes : List Quote }


makeRequest : String -> Shared -> (RemoteData (Graphql.Http.Error Response) Response -> msg) -> Cmd msg
makeRequest id shared gotResponseMsg =
    getQuotesForUser id
        |> Graphql.Http.queryRequest shared.supabase.supabaseUrl
        |> Graphql.Http.send (RemoteData.fromResult >> gotResponseMsg)



-- TODO: understand how to pass in the id to the filter, which has a custom scarlar type


getQuotesForUser : String -> SelectionSet Response RootQuery
getQuotesForUser _ =
    Query.quotesCollection
        (\optionals ->
            { optionals
                | first = Present 1
                , last = Present 20
            }
        )
        quotesCollection
        |> SelectionSet.nonNullOrFail


quotesCollection : SelectionSet Response MitsumoriApi.Object.QuotesConnection
quotesCollection =
    SelectionSet.succeed Response
        |> SelectionSet.with quotesEdges


quotesEdges : SelectionSet (List Quote) MitsumoriApi.Object.QuotesConnection
quotesEdges =
    QuotesConnection.edges
        (QuotesEdge.node quotesNode
         -- |> SelectionSet.nonNullOrFail
        )



-- TODO: custom scalar codecs here so we don't have to map each time


quotesNode : SelectionSet Quote MitsumoriApi.Object.Quotes
quotesNode =
    SelectionSet.map6 Quote
        (SelectionSet.map
            (\uuid ->
                case uuid of
                    MitsumoriApi.Scalar.Uuid string ->
                        string
            )
            Quotes.id
        )
        Quotes.quote_text
        Quotes.quote_author
        (SelectionSet.map
            (\date ->
                case date of
                    MitsumoriApi.Scalar.Datetime string ->
                        string
            )
            Quotes.created_at
        )
        (SelectionSet.map
            (\uuid ->
                case uuid of
                    MitsumoriApi.Scalar.Uuid string ->
                        string
            )
            Quotes.user_id
        )
        Quotes.quote_reference
