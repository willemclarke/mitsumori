port module Supabase exposing (AuthError, Quote, Quotes, authErrorDecoder, deleteQuote, editQuote, getQuotes, getSession, insertQuote, quotesQuery, sessionResponse, signIn, signInResponse, signOut, signOutResponse, signUp, signUpResponse)

import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.OptionalArgument as OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Json.Decode as JD
import Json.Encode as JE
import MitsumoriApi.Enum.OrderByDirection exposing (OrderByDirection(..))
import MitsumoriApi.Mutation as Mutation
import MitsumoriApi.Object
import MitsumoriApi.Object.Quote_tags as QuoteTags
import MitsumoriApi.Object.Quote_tagsConnection as QuoteTagsConnection
import MitsumoriApi.Object.Quote_tagsEdge as QuoteTagsEdge
import MitsumoriApi.Object.Quotes as Quotes
import MitsumoriApi.Object.QuotesConnection as QuotesConnection
import MitsumoriApi.Object.QuotesDeleteResponse
import MitsumoriApi.Object.QuotesEdge as QuotesEdge
import MitsumoriApi.Object.QuotesInsertResponse
import MitsumoriApi.Object.QuotesUpdateResponse
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
    , tags : Tags
    }


type alias Tags =
    Maybe (List String)



{- This type (PartialQuote) is used for quote mutations, as we seed a quote_id, and created_at field on entry to the database,
   so we don't have to generate an ID and pass the timestamp in
-}


type alias PartialQuote =
    { quote : String
    , author : String
    , userId : String
    , reference : Maybe String
    }


getQuotes : (RemoteData (Graphql.Http.Error Quotes) Quotes -> msg) -> Shared -> Cmd msg
getQuotes gotResponseMsg { user, supabase } =
    quotesQuery
        |> Graphql.Http.queryRequest supabase.supabaseUrl
        |> Graphql.Http.withHeader "apikey" supabase.supabaseKey
        |> Graphql.Http.withHeader "Authorization" ("Bearer " ++ User.userJwt user)
        |> Graphql.Http.send (RemoteData.fromResult >> gotResponseMsg)


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


deleteQuote :
    (RemoteData (Graphql.Http.Error (List Quote)) (List Quote) -> msg)
    -> String
    -> Shared
    -> Cmd msg
deleteQuote gotResponseMsg quoteId { user, supabase } =
    deleteQuoteMutation quoteId
        |> Graphql.Http.mutationRequest supabase.supabaseUrl
        |> Graphql.Http.withHeader "apikey" supabase.supabaseKey
        |> Graphql.Http.withHeader "Authorization" ("Bearer " ++ User.userJwt user)
        |> Graphql.Http.send (RemoteData.fromResult >> gotResponseMsg)


editQuote :
    (RemoteData (Graphql.Http.Error (List Quote)) (List Quote) -> msg)
    -> Quote
    -> Shared
    -> Cmd msg
editQuote gotResponseMsg quote { user, supabase } =
    editQuoteMutation quote
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
              , quote_reference = OptionalArgument.fromMaybe quote.reference
              }
            ]
        }
        (MitsumoriApi.Object.QuotesInsertResponse.records quotesNode)
        |> SelectionSet.nonNullOrFail


deleteQuoteMutation : String -> SelectionSet (List Quote) RootMutation
deleteQuoteMutation quoteId =
    Mutation.deleteFromquotesCollection
        (\optionals ->
            { optionals
                | filter =
                    Present
                        { id = Present { eq = Present quoteId, in_ = Absent, neq = Absent }
                        , quote_text = Absent
                        , quote_author = Absent
                        , user_id = Absent
                        , created_at = Absent
                        , quote_reference = Absent
                        }
            }
        )
        { atMost = 1 }
        (MitsumoriApi.Object.QuotesDeleteResponse.records quotesNode)


editQuoteMutation : Quote -> SelectionSet (List Quote) RootMutation
editQuoteMutation quote =
    Mutation.updatequotesCollection
        (\optionals ->
            { optionals
                | filter =
                    Present
                        { id = Present { eq = Present quote.id, in_ = Absent, neq = Absent }
                        , quote_text = Absent
                        , quote_author = Absent
                        , user_id = Absent
                        , created_at = Absent
                        , quote_reference = Absent
                        }
            }
        )
        { set =
            { id = Absent
            , quote_text = Present quote.quote
            , quote_author = Present quote.author
            , user_id = Absent
            , created_at = Absent
            , quote_reference = OptionalArgument.fromMaybe quote.reference
            }
        , atMost = 1
        }
        (MitsumoriApi.Object.QuotesUpdateResponse.records quotesNode)



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
    SelectionSet.map7 Quote
        Quotes.id
        Quotes.quote_text
        Quotes.quote_author
        Quotes.created_at
        Quotes.user_id
        Quotes.quote_reference
        quoteTagsCollection


quotesNodeForMutation : String -> SelectionSet Quote MitsumoriApi.Object.Quotes
quotesNodeForMutation quoteId =
    SelectionSet.map7 Quote
        Quotes.id
        Quotes.quote_text
        Quotes.quote_author
        Quotes.created_at
        Quotes.user_id
        Quotes.quote_reference
        (quoteTagsCollectionFromId quoteId)


quoteTagsCollectionFromId : String -> SelectionSet Tags MitsumoriApi.Object.Quotes
quoteTagsCollectionFromId quoteId =
    Quotes.quote_tagsCollection
        (\optionals ->
            { optionals
                | filter =
                    Present
                        { quote_id =
                            Present
                                { eq = Present quoteId, in_ = Absent, neq = Absent }
                        , text = Absent
                        , id = Absent
                        }
            }
        )
        quoteTagEdges


quoteTagsCollection : SelectionSet Tags MitsumoriApi.Object.Quotes
quoteTagsCollection =
    Quotes.quote_tagsCollection (\optionals -> optionals) quoteTagEdges


quoteTagEdges : SelectionSet (List String) MitsumoriApi.Object.Quote_tagsConnection
quoteTagEdges =
    QuoteTagsConnection.edges (QuoteTagsEdge.node quoteTagsNode)


quoteTagsNode : SelectionSet String MitsumoriApi.Object.Quote_tags
quoteTagsNode =
    QuoteTags.text



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


port signUp : JE.Value -> Cmd msg


port signUpResponse : (JE.Value -> msg) -> Sub msg


port signIn : JE.Value -> Cmd msg


port signInResponse : (JE.Value -> msg) -> Sub msg


port signOut : () -> Cmd msg


port signOutResponse : (JE.Value -> msg) -> Sub msg


port getSession : () -> Cmd msg


port sessionResponse : (JE.Value -> msg) -> Sub msg
