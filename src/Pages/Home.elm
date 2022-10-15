module Pages.Home exposing (Model, Msg(..), init, subscriptions, update, view, viewQuoteModal)

import Components.Icons as Icons
import Components.Modal as Modal
import Components.Spinner as Spinner
import Graphql.Http
import Html exposing (Html, a, button, div, form, header, input, label, p, text, ul)
import Html.Attributes exposing (class, classList, for, href, id, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Extra as HE
import Json.Decode as JD
import Json.Encode as JE
import Json.Encode.Extra
import List.Extra as LE
import Quotes
import Random exposing (Seed)
import RemoteData exposing (RemoteData(..))
import Shared exposing (Shared)
import String.Extra as SE
import Supabase
import User
import Uuid exposing (Uuid)



-- MODEL


type alias Model =
    { quotes : QuotesResponse
    , modalForm : ModalForm
    , modalFormProblems : List Problem
    , modalIsLoading : Bool
    , modalVisibility : ModalVisibility
    , modalType : ModalType
    }


type alias QuotesResponse =
    RemoteData (Graphql.Http.Error Quotes.Response) Quotes.Response


type alias Quote =
    { id : String
    , quote : String
    , author : String
    , createdAt : String
    , userId : String
    , reference : String
    }


type alias ModalForm =
    { quote : String
    , author : String
    , reference : Maybe String
    }


type Problem
    = InvalidEntry ValidatedField String
    | ServerError Supabase.AuthError


type ModalType
    = NewQuote
    | Editing Quotes.Quote
    | Delete Quotes.Quote


type ModalVisibility
    = Visible
    | Hidden


type ValidatedField
    = Quote_
    | Author
    | Reference


type TrimmedForm
    = Trimmed ModalForm



-- TODO: QuotesError needs a new `Supabase.DbError` or something, as the auth error type differs from postgres related


type QuoteResponse
    = QuotesOk (List Supabase.Quote)
    | QuotesError Supabase.AuthError
    | PayloadError


init : Shared -> ( Model, Cmd Msg )
init shared =
    ( { quotes = RemoteData.Loading
      , modalForm = { quote = "", author = "", reference = Nothing }
      , modalFormProblems = []
      , modalIsLoading = False
      , modalType = NewQuote
      , modalVisibility = Hidden
      }
    , Quotes.makeRequest GotQuotesResponse shared
      -- , Supabase.getQuotes (JE.string <| Maybe.withDefault "" (User.userId shared.user))
    )


quoteResponseDecoder : JE.Value -> QuoteResponse
quoteResponseDecoder json =
    JD.decodeValue
        (JD.oneOf
            [ JD.map QuotesOk (JD.list Supabase.quoteDecoder), JD.map QuotesError Supabase.errorDecoder ]
        )
        json
        |> Result.withDefault PayloadError


quoteFromSupabaseQuote : Supabase.Quote -> Quote
quoteFromSupabaseQuote quote =
    { id = quote.id
    , quote = quote.quote_text
    , author = quote.quote_author
    , createdAt = quote.created_at
    , userId = quote.user_id
    , reference = Maybe.withDefault "" quote.quote_reference
    }


encodeQuote : TrimmedForm -> Maybe Uuid.Uuid -> User.User -> JE.Value
encodeQuote (Trimmed form) quoteId user =
    JE.object
        [ ( "quote", JE.string form.quote )
        , ( "author", JE.string form.author )
        , ( "reference", Json.Encode.Extra.maybe JE.string form.reference )
        , ( "userId", Json.Encode.Extra.maybe JE.string (User.userId user) )
        , ( "quoteId", Json.Encode.Extra.maybe Uuid.encode quoteId )
        ]



-- UPDATE


type Msg
    = OpenAddQuoteModal
    | CloseModal
    | OnQuoteChange String
    | OnAuthorChange String
    | OnReferenceChange String
    | OpenEditQuoteModal Quotes.Quote
    | OpenDeleteQuoteModal Quotes.Quote
    | SubmitAddQuoteModal
    | SubmitEditQuoteModal Uuid.Uuid
      -- | SubmitDeleteQuoteModal String
    | GotQuotesResponse QuotesResponse
      -- | GotQuotesResponse JD.Value
    | NoOp


update : Shared -> Msg -> Model -> ( Model, Cmd msg, Shared.SharedUpdate )
update shared msg model =
    case msg of
        OpenAddQuoteModal ->
            ( { model | modalVisibility = Visible }, Cmd.none, Shared.NoUpdate )

        CloseModal ->
            ( { model | modalType = NewQuote, modalVisibility = Hidden, modalForm = emptyModalForm, modalFormProblems = [] }, Cmd.none, Shared.NoUpdate )

        OnQuoteChange quote ->
            updateModalForm (\form -> { form | quote = quote }) model

        OnAuthorChange author ->
            updateModalForm (\form -> { form | author = author }) model

        OnReferenceChange reference ->
            updateModalForm (\form -> { form | reference = Just reference }) model

        {- If we edit a quote, update the modalForm with the quotes values, also pass the Quote to the `Editing`
           constructor so when we submit the modal, we have the ID of the quote for supabase to use.
        -}
        OpenEditQuoteModal quote ->
            ( { model
                | modalForm = { quote = quote.quote, author = quote.author, reference = quote.reference }
                , modalType = Editing quote
                , modalVisibility = Visible
              }
            , Cmd.none
            , Shared.NoUpdate
            )

        OpenDeleteQuoteModal quote ->
            ( { model | modalType = Delete quote, modalVisibility = Visible }, Cmd.none, Shared.NoUpdate )

        SubmitAddQuoteModal ->
            case validateForm model.modalForm of
                Ok validForm ->
                    let
                        encodedQuote =
                            encodeQuote validForm Nothing shared.user
                    in
                    ( { model | modalFormProblems = [], modalIsLoading = True }, Supabase.addQuote encodedQuote, Shared.NoUpdate )

                Err problems ->
                    ( { model | modalFormProblems = problems }, Cmd.none, Shared.NoUpdate )

        SubmitEditQuoteModal quoteId ->
            case validateForm model.modalForm of
                Ok validForm ->
                    let
                        encodedQuote =
                            encodeQuote validForm (Just quoteId) shared.user
                    in
                    ( { model | modalFormProblems = [], modalIsLoading = True }, Supabase.editQuote encodedQuote, Shared.NoUpdate )

                Err problems ->
                    ( { model | modalFormProblems = problems }, Cmd.none, Shared.NoUpdate )

        GotQuotesResponse quotesResponse ->
            ( { model | quotes = quotesResponse }, Cmd.none, Shared.NoUpdate )

        -- SubmitDeleteQuoteModal quoteId ->
        --     let
        --         matchingQuote =
        --             LE.find (\quote -> quote.id == quoteId) model.quotes
        --         encodedQuote =
        --             matchingQuote
        --                 |> Maybe.map
        --                     (\quote ->
        --                         JE.object
        --                             [ ( "quoteId", JE.string quote.id )
        --                             , ( "userId", Json.Encode.Extra.maybe JE.string (User.userId shared.user) )
        --                             ]
        --                     )
        --                 |> Maybe.withDefault JE.null
        --     in
        --     ( { model | modalIsLoading = True }, Supabase.deleteQuote encodedQuote, Shared.NoUpdate )
        -- GotQuotesResponse json ->
        --     let
        --         quoteResponse =
        --             quoteResponseDecoder json
        --     in
        --     case quoteResponse of
        --         QuotesOk supabaseQuotes ->
        --             let
        --                 mappedQuotes =
        --                     List.map quoteFromSupabaseQuote supabaseQuotes
        --             in
        --             ( { model | quotes = mappedQuotes, modalIsLoading = False, modalForm = emptyModalForm, modalType = NewQuote, modalVisibility = Hidden }, Cmd.none, Shared.NoUpdate )
        --         QuotesError error ->
        --             let
        --                 serverErrors =
        --                     List.map ServerError [ error ]
        --             in
        --             ( { model | modalFormProblems = List.append model.modalFormProblems serverErrors, modalIsLoading = False }, Cmd.none, Shared.NoUpdate )
        --         PayloadError ->
        --             ( model, Cmd.none, Shared.NoUpdate )
        NoOp ->
            ( model, Cmd.none, Shared.NoUpdate )


emptyModalForm : ModalForm
emptyModalForm =
    { quote = "", author = "", reference = Nothing }


updateModalForm : (ModalForm -> ModalForm) -> Model -> ( Model, Cmd msg, Shared.SharedUpdate )
updateModalForm transform model =
    ( { model | modalForm = transform model.modalForm }, Cmd.none, Shared.NoUpdate )


generateUuid : Seed -> Uuid
generateUuid seed =
    Tuple.first <| Random.step Uuid.uuidGenerator seed


step : Seed -> Seed
step =
    Tuple.second << Random.step (Random.int Random.minInt Random.maxInt)



-- FORM HELPERS


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Quote_, Author ]


validateForm : ModalForm -> Result (List Problem) TrimmedForm
validateForm form =
    let
        trimmedForm =
            trimFields form
    in
    case List.concatMap (validateField trimmedForm) fieldsToValidate of
        [] ->
            Ok trimmedForm

        problems ->
            Err problems


validateField : TrimmedForm -> ValidatedField -> List Problem
validateField (Trimmed form) field =
    List.map (InvalidEntry field) <|
        case field of
            Quote_ ->
                if String.isEmpty form.quote then
                    [ "Quote can't be blank" ]

                else
                    []

            Author ->
                if String.isEmpty form.author then
                    [ "Author can't be blank" ]

                else
                    []

            Reference ->
                []


trimFields : ModalForm -> TrimmedForm
trimFields form =
    Trimmed
        { quote = String.trim form.quote
        , author = String.trim form.author
        , reference = Just (String.trim <| Maybe.withDefault "" form.reference)
        }


invalidEntryToString : List Problem -> ValidatedField -> String
invalidEntryToString problems field =
    getInvalidEntry problems field
        |> List.map problemToString
        |> String.join ""


serverErrorToString : List Problem -> String
serverErrorToString problems =
    getServerError problems
        |> List.map problemToString
        |> String.join ""


getInvalidEntry : List Problem -> ValidatedField -> List Problem
getInvalidEntry problems validatedField =
    List.filter
        (\problem ->
            case problem of
                InvalidEntry field _ ->
                    field == validatedField

                _ ->
                    False
        )
        problems


getServerError : List Problem -> List Problem
getServerError problems =
    List.filter
        (\problem ->
            case problem of
                ServerError _ ->
                    True

                InvalidEntry _ _ ->
                    False
        )
        problems


problemToString : Problem -> String
problemToString problem =
    case problem of
        InvalidEntry _ str ->
            str

        ServerError { message } ->
            message



-- VIEW


view : Shared -> Model -> Html Msg
view shared model =
    div
        [ class "flex flex-col h-full w-full items-center" ]
        [ viewHeader shared.user model.modalForm model.modalFormProblems model.modalType model.modalVisibility model.modalIsLoading
        , viewQuotes model.quotes
        ]


viewHeader : User.User -> ModalForm -> List Problem -> ModalType -> ModalVisibility -> Bool -> Html Msg
viewHeader user form problems modalType visibility isLoading =
    let
        username =
            (SE.toSentenceCase <| User.username user) ++ "'s"
    in
    div [ class "flex flex-col mt-16" ]
        [ div [ class "flex items-center" ]
            [ header [ class "text-3xl font-serif font-light mr-2" ] [ text <| String.join " " [ username, "quotes" ] ]
            , addQuoteButton form problems modalType visibility isLoading
            ]
        ]


addQuoteButton : ModalForm -> List Problem -> ModalType -> ModalVisibility -> Bool -> Html Msg
addQuoteButton form problems modalType visibility isLoading =
    div [ class "flex justify-end" ]
        [ button [ class "transition ease-in-out hover:-translate-y-0.5 duration-300", onClick OpenAddQuoteModal ] [ Icons.plus ]
        , viewQuoteModal form problems modalType visibility isLoading
        ]


viewQuotes : QuotesResponse -> Html Msg
viewQuotes quotesData =
    let
        content =
            case quotesData of
                RemoteData.Loading ->
                    [ Spinner.spinner ]

                RemoteData.Success quotes ->
                    List.map viewQuote quotes.quotes

                _ ->
                    [ HE.nothing ]
    in
    div [ class "text-start px-16 mt-10" ]
        [ div [ class "mb-12 grid grid-rows-4 sm:grid-cols-1 lg:grid-cols-3 gap-x-6 gap-y-6" ] content
        ]


viewQuote : Quotes.Quote -> Html Msg
viewQuote quote =
    let
        quoteTags =
            [ "Stoicism", "Roman" ]
                |> List.map viewQuoteTag

        reference =
            Maybe.withDefault "" quote.reference

        viewQuoteReference =
            if String.isEmpty reference then
                HE.nothing

            else
                div [ class "mt-1" ] [ a [ href <| reference, class "text-gray-600 text-sm cursor-pointer hover:text-black" ] [ text "Quote reference" ] ]
    in
    div [ class "flex flex-col border rounded-lg p-6 shadow-sm hover:bg-gray-100/30 transition ease-in-out hover:-translate-y-px duration-300" ]
        [ p [ class "text-lg text-gray-800" ] [ text quote.quote ]
        , p [ class "mt-1 text-gray-600 text-md font-light" ] [ text <| "by " ++ quote.author ]
        , div [ class "flex flex-col mt-2" ]
            [ div [ class "flex space-x-2" ] quoteTags
            , viewQuoteReference
            ]
        , div [ class "flex justify-between mt-3" ]
            [ button [ onClick <| OpenEditQuoteModal quote ] [ Icons.edit ]
            , button [ onClick <| OpenDeleteQuoteModal quote ] [ Icons.delete ]
            ]
        ]


viewQuoteTag : String -> Html msg
viewQuoteTag tag =
    div [ class "flex justify-center items-center rounded-lg text-xs text-white p-1 bg-gray-800" ] [ p [ class "m-1" ] [ text tag ] ]



{- This fn is responsible for displaying each type of Modal (adding a quote, editing, deleting) -}


viewQuoteModal : ModalForm -> List Problem -> ModalType -> ModalVisibility -> Bool -> Html Msg
viewQuoteModal form problems modalType visibility isLoading =
    case visibility of
        Visible ->
            case modalType of
                NewQuote ->
                    Modal.create
                        { title = "Add quote"
                        , body = viewModalFormBody form problems
                        , actions =
                            Modal.acceptAndDiscardActions
                                (Modal.asyncAction { label = "Add quote", onClick = SubmitAddQuoteModal, isLoading = isLoading })
                                (Modal.basicAction "Cancel" CloseModal)
                        }
                        |> Modal.view

                Editing quote ->
                    Modal.create
                        { title = "Edit quote"
                        , body = viewModalFormBody form problems
                        , actions =
                            Modal.acceptAndDiscardActions
                                (Modal.asyncAction { label = "Edit quote", onClick = SubmitEditQuoteModal quote.id, isLoading = isLoading })
                                (Modal.basicAction "Cancel" CloseModal)
                        }
                        |> Modal.view

                _ ->
                    HE.nothing

        -- Delete quote ->
        --     Modal.create
        --         { title = "Delete quote"
        --         , body = p [ class "text-lg text-gray-900" ] [ text "Are you sure you want to delete the quote?" ]
        --         , actions =
        --             Modal.acceptAndDiscardActions
        --                 (Modal.asyncAction { label = "Delete quote", onClick = SubmitDeleteQuoteModal quote.id, isLoading = isLoading })
        --                 (Modal.basicAction "Cancel" CloseModal)
        --         }
        --         |> Modal.view
        Hidden ->
            HE.nothing


viewModalFormBody : ModalForm -> List Problem -> Html Msg
viewModalFormBody form problems =
    div [ class "flex flex-col text-black" ]
        [ Html.form [ id "add-quote-form" ]
            [ div [ class "flex flex-col mt-2" ]
                [ label [ class "text-gray-900", for "quote" ]
                    [ text "Quote body" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", not (String.isEmpty <| invalidEntryToString problems Quote_) ) ]
                    , id "quote"
                    , value form.quote
                    , placeholder "Type quote here"
                    , type_ "text"
                    , onInput OnQuoteChange
                    ]
                    [ text form.quote ]
                , viewFormInvalidEntry problems Quote_
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-900 mt-2", for "author" ]
                    [ text "Author" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", not (String.isEmpty <| invalidEntryToString problems Author) ) ]
                    , id "author"
                    , value form.author
                    , placeholder "Author"
                    , type_ "text"
                    , onInput OnAuthorChange
                    ]
                    [ text form.author ]
                , viewFormInvalidEntry problems Author
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-900 mt-2", for "reference" ]
                    [ text "Reference" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , id "reference"
                    , value <| Maybe.withDefault "" form.reference
                    , placeholder "https://link-to-the-quote.com"
                    , type_ "text"
                    , onInput OnReferenceChange
                    ]
                    [ text form.author ]
                ]
            , viewFormServerError problems
            ]
        ]


viewFormInvalidEntry : List Problem -> ValidatedField -> Html msg
viewFormInvalidEntry problems field =
    div [ class "h-1" ] [ p [ class "text-sm text-red-500 mt-2" ] [ text <| invalidEntryToString problems field ] ]


viewFormServerError : List Problem -> Html msg
viewFormServerError problems =
    div [ class "h-1" ] [ p [ class "text-sm mt-1 text-red-500" ] [ text <| serverErrorToString problems ] ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- Supabase.quoteResponse GotQuotesResponse
