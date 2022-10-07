module Pages.Home exposing (Model, Msg(..), init, subscriptions, update, view)

import Components.Modal as Modal
import Html exposing (Html, a, button, div, form, header, input, label, p, text, ul)
import Html.Attributes exposing (class, classList, for, href, id, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Extra as HE
import Json.Decode as JD
import Json.Encode as JE
import Json.Encode.Extra
import Random exposing (Seed)
import Shared exposing (Shared)
import String.Extra as SE
import Supabase
import Svg
import Svg.Attributes as SvgAttrs
import User
import Uuid exposing (Uuid)



-- MODEL


type alias Model =
    { quotes : List Quote
    , modalForm : ModalForm
    , modalFormProblems : List Problem
    , modalIsLoading : Bool
    , modalVisibility : ModalVisibility
    , modalType : ModalType
    }


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
    , reference : String
    }


type Problem
    = InvalidEntry ValidatedField String
    | ServerError Supabase.Error


type ModalType
    = NewQuote
    | Editing Quote


type ModalVisibility
    = Visible
    | Hidden


type ValidatedField
    = Quote_
    | Author
    | Reference


type TrimmedForm
    = Trimmed ModalForm


type QuoteResponse
    = QuotesOk (List Supabase.Quote)
    | QuotesError Supabase.Error
    | PayloadError


init : Shared -> ( Model, Cmd Msg )
init shared =
    ( { quotes = []
      , modalForm = { quote = "", author = "", reference = "" }
      , modalFormProblems = []
      , modalIsLoading = False
      , modalType = NewQuote
      , modalVisibility = Hidden
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
    , reference = Maybe.withDefault "" quote.quote_reference
    }


encodeQuote : TrimmedForm -> Maybe String -> User.User -> JE.Value
encodeQuote (Trimmed form) id user =
    JE.object
        [ ( "quote", JE.string form.quote )
        , ( "author", JE.string form.author )
        , ( "reference", JE.string form.reference )
        , ( "userId", Json.Encode.Extra.maybe JE.string (User.userId user) )
        , ( "quoteId", Json.Encode.Extra.maybe JE.string id )
        ]



-- UPDATE


type Msg
    = OpenAddQuoteModal
    | CloseModal
    | OnQuoteChange String
    | OnAuthorChange String
    | OnReferenceChange String
    | OpenEditQuoteModal Quote
    | SubmitAddQuoteModal
    | SubmitEditQuoteModal String
    | GotQuotesResponse JD.Value
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
            updateModalForm (\form -> { form | reference = reference }) model

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
                    ( { model | quotes = mappedQuotes, modalIsLoading = False, modalForm = emptyModalForm, modalType = NewQuote, modalVisibility = Hidden }, Cmd.none, Shared.NoUpdate )

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
    { quote = "", author = "", reference = "" }


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
        , reference = String.trim form.reference
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
        [ viewHeader shared.user model.modalForm model.modalFormProblems model.modalType model.modalVisibility
        , viewQuotes model.quotes
        ]


viewHeader : User.User -> ModalForm -> List Problem -> ModalType -> ModalVisibility -> Html Msg
viewHeader user form problems modalType visibility =
    let
        username =
            (SE.toSentenceCase <| User.username user) ++ "'s"
    in
    div [ class "flex flex-col mt-16" ]
        [ div [ class "flex items-center" ]
            [ header [ class "text-4xl font-serif font-light mr-3" ] [ text <| String.join " " [ username, "quotes" ] ]
            , pencilSquareIcon
            ]
        , addQuoteButton form problems modalType visibility
        ]


pencilSquareIcon : Html msg
pencilSquareIcon =
    Svg.svg
        [ SvgAttrs.class "h-12 w-12"
        , SvgAttrs.fill "none"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.strokeWidth "1.5"
        , SvgAttrs.stroke "currentColor"
        ]
        [ Svg.path [ SvgAttrs.strokeLinecap "round", SvgAttrs.strokeLinejoin "round", SvgAttrs.d "M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10" ] [] ]


addQuoteButton : ModalForm -> List Problem -> ModalType -> ModalVisibility -> Html Msg
addQuoteButton form problems modalType visibility =
    div [ class "flex justify-end" ]
        [ button [ class "text-gray-700 hover:text-black", onClick OpenAddQuoteModal ] [ text "Add quote" ]
        , viewAddQuoteModal form problems modalType visibility
        ]


viewQuotes : List Quote -> Html Msg
viewQuotes quotes =
    div [ class "mx-6 text-start" ]
        [ ul [] (List.map viewQuote quotes)
        ]


viewQuote : Quote -> Html Msg
viewQuote quote =
    let
        quoteTags =
            [ "Stoicism", "Roman" ]
                |> List.map viewQuoteTag

        quoteReference =
            if String.isEmpty quote.reference then
                HE.nothing

            else
                div [ class "flex justify-end" ] [ a [ href <| quote.reference, class "text-gray-600 text-xs cursor-pointer hover:text-black" ] [ text "Quote reference" ] ]
    in
    div [ class "items-center my-7 cursor-default border rounded-lg p-4 shadow-sm" ]
        [ p [ class "text-lg font-normal" ] [ text quote.quote ]
        , p [ class "text-gray-600 text-md font-medium" ]
            [ text <| "- " ++ quote.author ]
        , div [ class "flex items-center justify-between" ]
            [ button [ onClick <| OpenEditQuoteModal quote, class "text-gray-600 text-xs font-medium mt-4 cursor-pointer hover:text-black" ] [ text "Edit quote" ]
            , div [ class "flex justify-end space-x-1" ] quoteTags
            ]
        , quoteReference
        ]


viewQuoteTag : String -> Html msg
viewQuoteTag tag =
    div [ class "flex justify-center rounded-lg text-sm text-white py-0.5 px-1 bg-lime-600" ] [ text tag ]


viewAddQuoteModal : ModalForm -> List Problem -> ModalType -> ModalVisibility -> Html Msg
viewAddQuoteModal form problems modalType visibility =
    case visibility of
        Visible ->
            case modalType of
                NewQuote ->
                    Modal.create
                        { title = "Add quote"
                        , body = viewModalFormBody form problems
                        , actions =
                            Modal.acceptAndDiscardActions
                                (Modal.basicAction "Add quote" SubmitAddQuoteModal)
                                (Modal.basicAction "Cancel" CloseModal)
                        }
                        |> Modal.view

                Editing quote ->
                    Modal.create
                        { title = "Edit quote"
                        , body = viewModalFormBody form problems
                        , actions =
                            Modal.acceptAndDiscardActions
                                (Modal.basicAction "Edit quote" (SubmitEditQuoteModal quote.id))
                                (Modal.basicAction "Cancel" CloseModal)
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
                    , value form.reference
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
    Supabase.quoteResponse GotQuotesResponse
