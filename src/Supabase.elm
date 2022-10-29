port module Supabase exposing (AuthError, Quote, Quotes, Tag, Tags, authErrorDecoder, deleteQuote, editQuote, getQuotes, getSession, insertQuote, insertQuoteTags, quotesQuery, sessionResponse, signIn, signInResponse, signOut, signOutResponse, signUp, signUpResponse)

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
import MitsumoriApi.Object.Quote_tagsInsertResponse
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
    List Tag


type alias Tag =
    { id : String
    , text : String
    , quoteId : String
    }


type alias InsertQuoteDto =
    { quote : String
    , author : String
    , userId : String
    , reference : Maybe String
    }


type alias QuoteTagsDto =
    { quoteId : String
    , tags : List String
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
    -> InsertQuoteDto
    -> Shared
    -> Cmd msg
insertQuote gotResponseMsg quote { user, supabase } =
    insertQuoteMutation quote
        |> Graphql.Http.mutationRequest supabase.supabaseUrl
        |> Graphql.Http.withHeader "apikey" supabase.supabaseKey
        |> Graphql.Http.withHeader "Authorization" ("Bearer " ++ User.userJwt user)
        |> Graphql.Http.send (RemoteData.fromResult >> gotResponseMsg)


insertQuoteTags :
    (RemoteData (Graphql.Http.Error (List Tag)) (List Tag) -> msg)
    -> QuoteTagsDto
    -> Shared
    -> Cmd msg
insertQuoteTags gotResponseMsg tag { user, supabase } =
    insertQuoteTagsMutation tag
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


insertQuoteMutation : InsertQuoteDto -> SelectionSet (List Quote) RootMutation
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
        (MitsumoriApi.Object.QuotesInsertResponse.records <| quoteNode)
        |> SelectionSet.nonNullOrFail


insertQuoteTagsMutation : QuoteTagsDto -> SelectionSet Tags RootMutation
insertQuoteTagsMutation tagsDto =
    let
        queryObjects =
            tagsDto.tags
                |> List.map (\tag -> { text = Present tag, quote_id = Present tagsDto.quoteId, id = Absent })
    in
    Mutation.insertIntoquote_tagsCollection { objects = queryObjects }
        (MitsumoriApi.Object.Quote_tagsInsertResponse.records <| quoteTagsNode)
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
        { atMost = 2 }
        (MitsumoriApi.Object.QuotesDeleteResponse.records <| quoteNodeForMutation quoteId)


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
        (MitsumoriApi.Object.QuotesUpdateResponse.records <| quoteNodeForMutation quote.id)



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
    QuotesConnection.edges (QuotesEdge.node quoteNode)



{- This quotes note gets a quote, with tags, used for fetching entire list of quotes -}


quoteNode : SelectionSet Quote MitsumoriApi.Object.Quotes
quoteNode =
    SelectionSet.map7 Quote
        Quotes.id
        Quotes.quote_text
        Quotes.quote_author
        Quotes.created_at
        Quotes.user_id
        Quotes.quote_reference
        quoteTagsCollection



{- This quotes node gets a quote for a specific ID, which in turn gets the tags for that quotes id -}


quoteNodeForMutation : String -> SelectionSet Quote MitsumoriApi.Object.Quotes
quoteNodeForMutation quoteId =
    SelectionSet.map7 Quote
        Quotes.id
        Quotes.quote_text
        Quotes.quote_author
        Quotes.created_at
        Quotes.user_id
        Quotes.quote_reference
        (quoteTagsCollectionFromId quoteId)



-- ^^ not sure if this is correct 29/10/2022


quoteTagsCollection : SelectionSet Tags MitsumoriApi.Object.Quotes
quoteTagsCollection =
    Quotes.quote_tagsCollection (\optionals -> optionals) quoteTagEdges
        |> SelectionSet.nonNullOrFail


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
        |> SelectionSet.nonNullOrFail


quoteTagEdges : SelectionSet Tags MitsumoriApi.Object.Quote_tagsConnection
quoteTagEdges =
    QuoteTagsConnection.edges (QuoteTagsEdge.node quoteTagsNode)


quoteTagsNode : SelectionSet Tag MitsumoriApi.Object.Quote_tags
quoteTagsNode =
    SelectionSet.map3 Tag
        QuoteTags.id
        QuoteTags.text
        QuoteTags.quote_id


quoteTagTextNode : SelectionSet String MitsumoriApi.Object.Quote_tags
quoteTagTextNode =
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
