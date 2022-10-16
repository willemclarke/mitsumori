port module Supabase exposing (AuthError, Quote, Quotes, addQuote, authErrorDecoder, deleteQuote, editQuote, getQuotes, getSession, insertQuote, quoteResponse, quotesQuery, sessionResponse, signIn, signInResponse, signOut, signOutResponse, signUp, signUpResponse)

import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Json.Decode as JD
import Json.Encode as JE
import MitsumoriApi.Enum.OrderByDirection exposing (OrderByDirection(..))
import MitsumoriApi.Mutation as Mutation
import MitsumoriApi.Object
import MitsumoriApi.Object.Quotes as Quotes
import MitsumoriApi.Object.QuotesConnection as QuotesConnection
import MitsumoriApi.Object.QuotesEdge as QuotesEdge
import MitsumoriApi.Object.QuotesInsertResponse
import MitsumoriApi.Query as Query
import RemoteData exposing (RemoteData)
import Shared exposing (Shared)
import Time
import User



{- This module is where all GraphQL functions and the Ports which call to supabase functions live
   -- Graphql Section
-}


type alias Quotes =
    { quotes : List Quote }


type alias Quote =
    { id : String
    , quote : String
    , author : String
    , createdAt : Time.Posix
    , userId : String
    , reference : Maybe String
    }



{- This type (PartialQuote) is used for quote mutations, as we seed a quote_id, and created_at field on entry to the database,
   so we don't have to generate an ID and pass the timestamp in
-}


type alias PartialQuote =
    { quote : String
    , author : String
    , userId : String
    , reference : Maybe String
    }


insertQuote :
    (RemoteData (Graphql.Http.Error (List Quote)) (List Quote) -> msg)
    -> PartialQuote
    -> Shared
    -> Cmd msg
insertQuote gotResponseMsg quote { user, supabase } =
    insertQuoteMutation quote
        |> Graphql.Http.mutationRequest supabase.supabaseUrl
        |> Graphql.Http.withHeader "apikey" supabase.supabaseKey
        |> Graphql.Http.withHeader "Authorization" ("Bearer " ++ User.userJwt user)
        |> Graphql.Http.send (RemoteData.fromResult >> gotResponseMsg)


insertQuoteMutation : PartialQuote -> SelectionSet (List Quote) RootMutation
insertQuoteMutation quote =
    Mutation.insertIntoquotesCollection
        { objects =
            [ { id = Absent
              , quote_text = Present quote.quote
              , quote_author = Present quote.author
              , user_id = Present quote.userId
              , created_at = Absent
              , quote_reference = Present <| Maybe.withDefault "" quote.reference
              }
            ]
        }
        (MitsumoriApi.Object.QuotesInsertResponse.records quotesNode)
        |> SelectionSet.nonNullOrFail


getQuotes : (RemoteData (Graphql.Http.Error Quotes) Quotes -> msg) -> Shared -> Cmd msg
getQuotes gotResponseMsg { user, supabase } =
    quotesQuery
        |> Graphql.Http.queryRequest supabase.supabaseUrl
        |> Graphql.Http.withHeader "apikey" supabase.supabaseKey
        |> Graphql.Http.withHeader "Authorization" ("Bearer " ++ User.userJwt user)
        |> Graphql.Http.send (RemoteData.fromResult >> gotResponseMsg)



-- TODO: understand how to pass in the id to the filter, which has a custom scarlar type


quotesQuery : SelectionSet Quotes RootQuery
quotesQuery =
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


quotesCollection : SelectionSet Quotes MitsumoriApi.Object.QuotesConnection
quotesCollection =
    SelectionSet.succeed Quotes
        |> SelectionSet.with quotesEdges


quotesEdges : SelectionSet (List Quote) MitsumoriApi.Object.QuotesConnection
quotesEdges =
    QuotesConnection.edges (QuotesEdge.node quotesNode)


quotesNode : SelectionSet Quote MitsumoriApi.Object.Quotes
quotesNode =
    SelectionSet.map6 Quote
        Quotes.id
        Quotes.quote_text
        Quotes.quote_author
        Quotes.created_at
        Quotes.user_id
        Quotes.quote_reference



{-
   -- Ports Section
    AuthError is the error type returned by Supabases auth functions:
      - signup, signin, logout, session
-}


type alias AuthError =
    { message : String
    , status : Int
    }


authErrorDecoder : JD.Decoder AuthError
authErrorDecoder =
    JD.map2 AuthError
        (JD.field "message" JD.string)
        (JD.field "status" JD.int)


port addQuote : JE.Value -> Cmd msg


port editQuote : JE.Value -> Cmd msg


port deleteQuote : JE.Value -> Cmd msg



{- `quoteResponse` is the port responsible for sending back a list of quotes, regardless of whether
   the outgoing port was `addQuote`, `editQuote` or `deleteQuote`
-}


port quoteResponse : (JE.Value -> msg) -> Sub msg


port signUp : JE.Value -> Cmd msg


port signUpResponse : (JE.Value -> msg) -> Sub msg


port signIn : JE.Value -> Cmd msg


port signInResponse : (JE.Value -> msg) -> Sub msg


port signOut : () -> Cmd msg


port signOutResponse : (JE.Value -> msg) -> Sub msg


port getSession : () -> Cmd msg


port sessionResponse : (JE.Value -> msg) -> Sub msg
