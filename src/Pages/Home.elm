module Pages.Home exposing (Model, Msg(..), init, subscriptions, update, view)

import Components.Button as Button
import Components.Modal as Modal
import Html exposing (Html, div, form, input, label, p, text, ul)
import Html.Attributes exposing (class, classList, for, id, placeholder, type_)
import Html.Events exposing (onInput)
import Html.Extra as HE
import Json.Decode as JD
import Json.Encode as JE
import Json.Encode.Extra
import Random exposing (Seed)
import Shared exposing (Shared)
import Supabase
import User
import Uuid exposing (Uuid)



-- MODEL


type alias Model =
    { quotes : List Quote
    , modalForm : ModalForm
    , modalFormProblems : List Problem
    , modalIsLoading : Bool
    , modalState : ModalState
    }


type alias Quote =
    { id : String
    , quote : String
    , author : String
    , createdAt : String
    , userId : String
    }


type alias ModalForm =
    { quote : String
    , author : String
    }


type Problem
    = InvalidEntry ValidatedField String
    | ServerError Supabase.Error


type ModalState
    = Visible
    | Hidden


type ValidatedField
    = Quote_
    | Author


type TrimmedForm
    = Trimmed ModalForm


type QuoteResponse
    = QuotesOk (List Supabase.Quote)
    | QuotesError Supabase.Error
    | PayloadError


init : Shared -> ( Model, Cmd Msg )
init shared =
    ( { quotes = []
      , modalForm = { quote = "", author = "" }
      , modalFormProblems = []
      , modalIsLoading = False
      , modalState = Hidden
      }
    , Supabase.getQuotes <| Maybe.withDefault "" (User.userId shared.user)
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
    }


encodeQuote : TrimmedForm -> User.User -> JE.Value
encodeQuote (Trimmed form) user =
    JE.object
        [ ( "quote", JE.string form.quote )
        , ( "author", JE.string form.author )
        , ( "userId", Json.Encode.Extra.maybe JE.string (User.userId user) )
        ]



-- UPDATE


type Msg
    = OnQuoteChange String
    | OnAuthorChange String
    | SubmitAddQuoteModal
    | GotQuotesResponse JD.Value
    | OpenAddQuoteModal
    | CloseModal
    | NoOp


update : Shared -> Msg -> Model -> ( Model, Cmd msg, Shared.SharedUpdate )
update shared msg model =
    case msg of
        OnQuoteChange quote ->
            updateModalForm (\form -> { form | quote = quote }) model

        OnAuthorChange author ->
            updateModalForm (\form -> { form | author = author }) model

        OpenAddQuoteModal ->
            ( { model | modalState = Visible }, Cmd.none, Shared.NoUpdate )

        CloseModal ->
            ( { model | modalState = Hidden, modalForm = emptyModalForm, modalFormProblems = [] }, Cmd.none, Shared.NoUpdate )

        SubmitAddQuoteModal ->
            case validateForm model.modalForm of
                Ok validForm ->
                    let
                        encodedQuote =
                            encodeQuote validForm shared.user
                    in
                    ( { model | modalFormProblems = [], modalIsLoading = True }, Supabase.addQuote encodedQuote, Shared.NoUpdate )

                Err problems ->
                    ( { model | modalFormProblems = problems }, Cmd.none, Shared.NoUpdate )

        GotQuotesResponse json ->
            let
                quoteResponse =
                    quoteResponseDecoder json
            in
            case quoteResponse of
                QuotesOk supabaseQuotes ->
                    let
                        mappedQuotes =
                            List.map quoteFromSupabaseQuote supabaseQuotes
                    in
                    ( { model | quotes = mappedQuotes, modalIsLoading = False, modalForm = emptyModalForm, modalState = Hidden }, Cmd.none, Shared.NoUpdate )

                QuotesError error ->
                    let
                        serverErrors =
                            List.map ServerError [ error ]
                    in
                    ( { model | modalFormProblems = List.append model.modalFormProblems serverErrors, modalIsLoading = False }, Cmd.none, Shared.NoUpdate )

                PayloadError ->
                    ( model, Cmd.none, Shared.NoUpdate )

        NoOp ->
            ( model, Cmd.none, Shared.NoUpdate )


emptyModalForm : ModalForm
emptyModalForm =
    { quote = "", author = "" }


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


trimFields : ModalForm -> TrimmedForm
trimFields form =
    Trimmed
        { quote = String.trim form.quote
        , author = String.trim form.author
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


view : Model -> Html Msg
view model =
    div
        [ class "flex flex-col h-full items-center" ]
        [ addQuoteButton model.modalForm model.modalFormProblems model.modalState
        , viewQuotes model.quotes
        ]


addQuoteButton : ModalForm -> List Problem -> ModalState -> Html Msg
addQuoteButton form problems modalState =
    div [ class "my-4" ]
        [ Button.create { label = "Add Quote", onClick = OpenAddQuoteModal } |> Button.view
        , viewAddQuoteModal form problems modalState
        ]


viewQuotes : List Quote -> Html msg
viewQuotes quotes =
    div [ class "mx-6 w-11/12 max-w-3xl text-start" ]
        [ ul [] (List.map viewQuote quotes)
        ]


viewQuote : Quote -> Html msg
viewQuote quote =
    div [ class "items-center my-6 cursor-default" ]
        [ p [ class "text-lg font-medium" ] [ text quote.quote ]
        , div [ class "flex justify-between" ]
            [ p [ class "text-gray-600 text-sm" ]
                [ text <| "--- " ++ quote.author ]
            ]
        ]


viewAddQuoteModal : ModalForm -> List Problem -> ModalState -> Html Msg
viewAddQuoteModal form problems modalState =
    case modalState of
        Visible ->
            Modal.create
                { title = "Add quote"
                , body = viewModalFormBody form problems
                , actions =
                    Modal.acceptAndDiscardActions (Modal.basicAction "Add quote" SubmitAddQuoteModal) (Modal.basicAction "Cancel" CloseModal)
                }
                |> Modal.view

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
                    , placeholder "Author"
                    , type_ "text"
                    , onInput OnAuthorChange
                    ]
                    [ text form.author ]
                , viewFormInvalidEntry problems Author
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
    Supabase.addQuoteResponse GotQuotesResponse
