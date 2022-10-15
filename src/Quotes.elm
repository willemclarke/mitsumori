module Quotes exposing (Quote, Response, makeRequest)

import Graphql.Http
import Graphql.Operation exposing (RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import MitsumoriApi.Enum.OrderByDirection exposing (OrderByDirection(..))
import MitsumoriApi.Object
import MitsumoriApi.Object.Quotes as Quotes
import MitsumoriApi.Object.QuotesConnection as QuotesConnection
import MitsumoriApi.Object.QuotesEdge as QuotesEdge
import MitsumoriApi.Query as Query
import MitsumoriApi.Scalar
import RemoteData exposing (RemoteData)
import Shared exposing (Shared)
import Time
import User
import Uuid



{- This module is to handle all GraphQL queries/mutations pertaining to Quotes -}


type alias Response =
    { quotes : List Quote }


type alias Quote =
    { id : Uuid.Uuid
    , quote : String
    , author : String
    , createdAt : Time.Posix
    , userId : Uuid.Uuid
    , reference : Maybe String
    }


makeRequest : (RemoteData (Graphql.Http.Error Response) Response -> msg) -> Shared -> Cmd msg
makeRequest gotResponseMsg { user, supabase } =
    getQuotes
        |> Graphql.Http.queryRequest supabase.supabaseUrl
        |> Graphql.Http.withHeader "apikey" supabase.supabaseKey
        |> Graphql.Http.withHeader "Authorization" ("Bearer " ++ User.userJwt user)
        |> Graphql.Http.send (RemoteData.fromResult >> gotResponseMsg)



-- TODO: understand how to pass in the id to the filter, which has a custom scarlar type


getQuotes : SelectionSet Response RootQuery
getQuotes =
    Query.quotesCollection
        (\optionals ->
            { optionals
                | first = Present 20
                , orderBy =
                    Present
                        [ { created_at = Present DescNullsLast
                          , id = Absent
                          , quote_text = Absent
                          , quote_author = Absent
                          , quote_reference = Absent
                          , user_id = Absent
                          }
                        ]
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
        Quotes.id
        Quotes.quote_text
        Quotes.quote_author
        Quotes.created_at
        Quotes.user_id
        Quotes.quote_reference
