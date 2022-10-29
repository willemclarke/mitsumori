module Pages.Home exposing (Model, Msg(..), init, subscriptions, update, view, viewQuoteModal)

import Components.Icons as Icons
import Components.Modal as Modal
import Components.Spinner as Spinner
import Components.Toast as Toast
import Dict
import Graphql.Http
import Html exposing (Html, a, button, div, form, header, input, label, p, text, textarea)
import Html.Attributes exposing (class, classList, for, href, id, maxlength, placeholder, rows, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Extra as HE
import RemoteData exposing (RemoteData(..))
import Shared exposing (Shared)
import String.Extra as SE
import Supabase
import User
import Validator.Maybe
import Validator.Named exposing (Validated)
import Validator.String



-- MODEL


type alias Model =
    { quotes : QuotesResponse
    , modalForm : ModalForm
    , modalFormProblems : List Problem
    , modalIsLoading : Bool
    , modalVisibility : ModalVisibility
    , modalType : ModalType
    , validated : Validated Problem ValidForm
    }


type alias QuotesResponse =
    RemoteData (Graphql.Http.Error Supabase.Quotes) Supabase.Quotes


type alias ModalForm =
    { quote : String
    , author : String
    , reference : Maybe String
    , tags : Maybe (List String)
    }


type alias ValidForm =
    { quote : String
    , author : String
    , reference : Maybe String
    , tags : Maybe (List String)
    }


type Problem
    = InvalidEntry Field String


type ModalType
    = NewQuote
    | Editing Supabase.Quote
    | Delete Supabase.Quote


type ModalVisibility
    = Visible
    | Hidden


type Field
    = Quote_
    | Author
    | Reference
    | Tags


init : Shared -> ( Model, Cmd Msg )
init shared =
    ( { quotes = RemoteData.Loading
      , modalForm = { quote = "", author = "", reference = Nothing, tags = Nothing }
      , modalFormProblems = []
      , modalIsLoading = False
      , modalType = NewQuote
      , modalVisibility = Hidden
      , validated = Err Dict.empty
      }
    , Supabase.getQuotes GotQuotesResponse shared
    )


supabaseTagsToString : Supabase.Tags -> Maybe (List String)
supabaseTagsToString tags =
    Just <| List.map (\tag -> tag.text) tags



-- UPDATE


type Msg
    = OpenAddQuoteModal
    | CloseModal
    | OnQuoteChange String
    | OnAuthorChange String
    | OnReferenceChange String
    | OnTagsChange String
    | OpenEditQuoteModal Supabase.Quote
    | OpenDeleteQuoteModal Supabase.Quote
    | SubmitAddQuoteModal
    | SubmitEditQuoteModal Supabase.Quote
    | SubmitDeleteQuoteModal String
    | GotQuotesResponse QuotesResponse
    | GotQuoteTagsResponse (RemoteData (Graphql.Http.Error (List Supabase.Tag)) (List Supabase.Tag))
    | GotInsertQuoteResponse (RemoteData (Graphql.Http.Error (List Supabase.Quote)) (List Supabase.Quote))
    | GotDeleteQuoteResponse (RemoteData (Graphql.Http.Error (List Supabase.Quote)) (List Supabase.Quote))
    | GotEditQuotesResponse (RemoteData (Graphql.Http.Error (List Supabase.Quote)) (List Supabase.Quote))
    | NoOp


update : Shared -> Msg -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
update shared msg model =
    case msg of
        OpenAddQuoteModal ->
            ( { model | modalVisibility = Visible }, Cmd.none, Shared.NoUpdate )

        CloseModal ->
            ( { model | modalType = NewQuote, modalVisibility = Hidden, modalForm = emptyModalForm, modalFormProblems = [], modalIsLoading = False }, Cmd.none, Shared.NoUpdate )

        OnQuoteChange quote ->
            updateModalForm (\form -> { form | quote = quote }) model

        OnAuthorChange author ->
            updateModalForm (\form -> { form | author = author }) model

        OnReferenceChange reference ->
            updateModalForm (\form -> { form | reference = Just reference }) model

        OnTagsChange tag ->
            updateModalForm (\form -> { form | tags = Just [ tag ] }) model

        {- If we edit a quote, update the modalForm with the quotes values, also pass the Quote to the `Editing`
           constructor so when we submit the modal, we have the ID of the quote for supabase to use.
        -}
        OpenEditQuoteModal quote ->
            ( { model
                | modalForm =
                    { quote = quote.quote
                    , author = quote.author
                    , reference = quote.reference
                    , tags = supabaseTagsToString quote.tags
                    }
                , modalType = Editing quote
                , modalVisibility = Visible
              }
            , Cmd.none
            , Shared.NoUpdate
            )

        OpenDeleteQuoteModal quote ->
            ( { model | modalType = Delete quote, modalVisibility = Visible }
            , Cmd.none
            , Shared.NoUpdate
            )

        SubmitAddQuoteModal ->
            let
                validatedForm =
                    validateForm model.modalForm
            in
            case validatedForm of
                Ok validForm ->
                    let
                        quote =
                            { quote = validForm.quote
                            , author = validForm.author
                            , reference = validForm.reference
                            , userId = Maybe.withDefault "" (User.userId shared.user)
                            }
                    in
                    ( { model | validated = validatedForm, modalIsLoading = True, quotes = RemoteData.Loading }
                    , Supabase.insertQuote GotInsertQuoteResponse quote shared
                    , Shared.NoUpdate
                    )

                Err _ ->
                    ( { model | validated = validatedForm }, Cmd.none, Shared.NoUpdate )

        SubmitEditQuoteModal quote ->
            let
                validatedForm =
                    validateForm model.modalForm
            in
            case validatedForm of
                Ok validForm ->
                    let
                        quote_ =
                            { id = quote.id
                            , quote = validForm.quote
                            , author = validForm.author
                            , reference = validForm.reference
                            , userId = quote.userId
                            , createdAt = quote.createdAt
                            , tags = quote.tags
                            }
                    in
                    ( { model | validated = validatedForm, modalIsLoading = True, modalForm = emptyModalForm }
                    , Supabase.editQuote GotEditQuotesResponse quote_ shared
                    , Shared.NoUpdate
                    )

                Err _ ->
                    ( { model | validated = validatedForm }, Cmd.none, Shared.NoUpdate )

        SubmitDeleteQuoteModal quoteId ->
            ( { model | modalIsLoading = True, modalForm = emptyModalForm }
            , Supabase.deleteQuote GotDeleteQuoteResponse quoteId shared
            , Shared.NoUpdate
            )

        GotQuotesResponse quotesResponse ->
            ( { model | quotes = quotesResponse }, Cmd.none, Shared.NoUpdate )

        -- TODO: handle case of error here better via toasts
        GotInsertQuoteResponse quotesResponse ->
            case quotesResponse of
                RemoteData.Success quotes ->
                    let
                        tags =
                            model.modalForm.tags |> Maybe.withDefault []

                        {- Have to get the head of the list as insertQuotes returns the quote in a list -}
                        quoteId =
                            List.head quotes
                                |> Maybe.map (\quote -> quote.id)
                                |> Maybe.withDefault ""

                        ( model_, cmd_ ) =
                            case tags of
                                [] ->
                                    ( { model | modalIsLoading = False, modalVisibility = Hidden, modalType = NewQuote }, Supabase.getQuotes GotQuotesResponse shared )

                                _ ->
                                    ( model, Supabase.insertQuoteTags GotQuoteTagsResponse { quoteId = quoteId, tags = tags } shared )
                    in
                    ( model_, cmd_, Shared.NoUpdate )

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

        GotQuoteTagsResponse response ->
            case response of
                RemoteData.Success _ ->
                    ( { model | modalVisibility = Hidden, modalType = NewQuote, modalIsLoading = False, modalForm = emptyModalForm }
                    , Supabase.getQuotes GotQuotesResponse shared
                    , Shared.ShowToast <| Toast.Success "Quote added successfully."
                    )

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

        GotDeleteQuoteResponse quotesResponse ->
            case quotesResponse of
                RemoteData.Success _ ->
                    ( { model | modalVisibility = Hidden, modalType = NewQuote, modalIsLoading = False }
                    , Supabase.getQuotes GotQuotesResponse shared
                    , Shared.ShowToast <| Toast.Success "Quote deleted successfully."
                    )

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

        GotEditQuotesResponse quotesResponse ->
            case quotesResponse of
                RemoteData.Success _ ->
                    ( { model | modalVisibility = Hidden, modalType = NewQuote, modalIsLoading = False }
                    , Supabase.getQuotes GotQuotesResponse shared
                    , Shared.ShowToast <| Toast.Success "Quote edited successfully."
                    )

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

        NoOp ->
            ( model, Cmd.none, Shared.NoUpdate )


emptyModalForm : ModalForm
emptyModalForm =
    { quote = "", author = "", reference = Nothing, tags = Nothing }


updateModalForm : (ModalForm -> ModalForm) -> Model -> ( Model, Cmd msg, Shared.SharedUpdate )
updateModalForm transform model =
    ( { model | modalForm = transform model.modalForm }, Cmd.none, Shared.NoUpdate )



-- FORM HELPERS


fieldToString : Field -> String
fieldToString field =
    case field of
        Quote_ ->
            "quote"

        Author ->
            "author"

        Reference ->
            "reference"

        Tags ->
            "tags"


validateForm : ModalForm -> Validated Problem ValidForm
validateForm form =
    let
        trimmedForm =
            trimFields form
    in
    Ok ValidForm
        |> Validator.Named.validateMany (fieldToString Quote_)
            [ Validator.String.notEmpty (InvalidEntry Quote_ "Quote can't be blank")
            , Validator.String.maxLength (InvalidEntry Quote_ "Quote can't exceed 250 chars") 250
            ]
            trimmedForm.quote
        |> Validator.Named.validate (fieldToString Author) (Validator.String.notEmpty (InvalidEntry Author "Author can't be blank")) trimmedForm.author
        |> Validator.Named.validate (fieldToString Reference) (Validator.Maybe.notRequired (Validator.String.isUrl (InvalidEntry Reference "Must be a valid URL, e.g. (www.google.com)"))) trimmedForm.reference
        |> Validator.Named.noCheck trimmedForm.tags


fieldHasError : Field -> Validated Problem ValidForm -> Bool
fieldHasError field validated =
    Validator.Named.hasErrorsOn (fieldToString field) validated


trimFields : ModalForm -> ModalForm
trimFields form =
    { quote = String.trim form.quote
    , author = String.trim form.author
    , reference = Maybe.map (\ref -> String.trim ref) form.reference
    , tags = Maybe.map (\tags -> List.map String.trim tags) form.tags
    }



-- VIEW


view : Shared -> Model -> Html Msg
view shared model =
    div
        [ class "flex flex-col h-full w-full items-center" ]
        [ viewHeader shared.user model.modalForm model.validated model.modalType model.modalVisibility model.modalIsLoading
        , viewQuotes model.quotes shared
        ]


viewHeader : User.User -> ModalForm -> Validated Problem ValidForm -> ModalType -> ModalVisibility -> Bool -> Html Msg
viewHeader user form validated modalType visibility isLoading =
    let
        username =
            (SE.toSentenceCase <| User.username user) ++ "'s"
    in
    div [ class "flex flex-col mt-16" ]
        [ div [ class "flex items-center" ]
            [ header [ class "text-3xl font-serif font-light mr-2" ] [ text <| String.join " " [ username, "quotes" ] ]
            , addQuoteButton form validated modalType visibility isLoading
            ]
        ]


addQuoteButton : ModalForm -> Validated Problem ValidForm -> ModalType -> ModalVisibility -> Bool -> Html Msg
addQuoteButton form validated modalType visibility isLoading =
    div [ class "flex justify-end" ]
        [ button [ class "transition ease-in-out hover:-translate-y-0.5 duration-300", onClick OpenAddQuoteModal ] [ Icons.plus ]
        , viewQuoteModal form validated modalType visibility isLoading
        ]


viewQuotes : QuotesResponse -> Shared -> Html Msg
viewQuotes quotesData shared =
    let
        content =
            case quotesData of
                RemoteData.Loading ->
                    div [ class "flex w-full h-full justify-center items-center" ] [ Spinner.spinner ]

                RemoteData.Success quotes ->
                    div [ class "grid grid-rows-4 sm:grid-cols-1 lg:grid-cols-3 gap-x-6 gap-y-6" ]
                        (List.map (\quote -> viewQuote shared quote) quotes.quotes)

                _ ->
                    HE.nothing
    in
    div [ class "mt-12 text-start px-6 md:px-12 lg:px-16 xl:px-16 2xl:px-18 h-full w-full" ] [ content ]


viewQuote : Shared -> Supabase.Quote -> Html Msg
viewQuote shared quote =
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
                div [ class "mt-1" ] [ a [ href <| reference, class "text-gray-600 text-sm cursor-pointer hover:text-black", target "_blank" ] [ text "Quote reference" ] ]
    in
    div [ class "flex flex-col border rounded-lg p-6 shadow-sm hover:bg-gray-100/30 transition ease-in-out hover:-translate-y-px duration-300" ]
        [ p [ class "text-lg text-gray-800" ] [ text quote.quote ]
        , p [ class "mt-1 text-gray-600 text-md font-light" ] [ text <| "by " ++ quote.author ]
        , div [ class "flex flex-col mt-2" ]
            [ div [ class "flex space-x-2" ] quoteTags
            , viewQuoteReference
            ]
        , viewEditAndDeleteIconButtons shared quote
        ]


viewEditAndDeleteIconButtons : Shared -> Supabase.Quote -> Html Msg
viewEditAndDeleteIconButtons shared quote =
    let
        userId =
            User.userId shared.user

        quoteUserId =
            Just quote.userId
    in
    if userId == quoteUserId then
        div [ class "flex justify-between mt-3" ]
            [ button [ onClick <| OpenEditQuoteModal quote ] [ Icons.edit ]
            , button [ onClick <| OpenDeleteQuoteModal quote ] [ Icons.delete ]
            ]

    else
        HE.nothing


viewQuoteTag : String -> Html msg
viewQuoteTag tag =
    div [ class "flex justify-center items-center rounded-lg text-xs text-white p-1 bg-gray-800" ] [ p [ class "m-1" ] [ text tag ] ]



{- This fn is responsible for displaying each type of Modal (adding a quote, editing, deleting) -}


viewQuoteModal : ModalForm -> Validated Problem ValidForm -> ModalType -> ModalVisibility -> Bool -> Html Msg
viewQuoteModal form validated modalType visibility isLoading =
    case visibility of
        Visible ->
            case modalType of
                NewQuote ->
                    Modal.create
                        { title = "Add quote"
                        , body = viewModalFormBody form validated
                        , actions =
                            Modal.acceptAndDiscardActions
                                (Modal.asyncAction { label = "Add quote", onClick = SubmitAddQuoteModal, isLoading = isLoading })
                                (Modal.basicAction "Cancel" CloseModal)
                        }
                        |> Modal.view

                Editing quote ->
                    Modal.create
                        { title = "Edit quote"
                        , body = viewModalFormBody form validated
                        , actions =
                            Modal.acceptAndDiscardActions
                                (Modal.asyncAction { label = "Edit quote", onClick = SubmitEditQuoteModal quote, isLoading = isLoading })
                                (Modal.basicAction "Cancel" CloseModal)
                        }
                        |> Modal.view

                Delete quote ->
                    Modal.create
                        { title = "Delete quote"
                        , body = p [ class "text-lg text-gray-900" ] [ text "Are you sure you want to delete the quote?" ]
                        , actions =
                            Modal.acceptAndDiscardActions
                                (Modal.asyncAction { label = "Delete quote", onClick = SubmitDeleteQuoteModal quote.id, isLoading = isLoading })
                                (Modal.basicAction "Cancel" CloseModal)
                        }
                        |> Modal.view

        Hidden ->
            HE.nothing


viewModalFormBody : ModalForm -> Validated Problem ValidForm -> Html Msg
viewModalFormBody form validated =
    div [ class "flex flex-col text-black" ]
        [ Html.form [ id "add-quote-form" ]
            [ div [ class "flex flex-col mt-2" ]
                [ label [ class "text-gray-900", for "quote" ]
                    [ text "Quote body" ]
                , textarea
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", fieldHasError Quote_ validated ) ]
                    , id "quote"
                    , rows 5
                    , maxlength 250
                    , value form.quote
                    , placeholder "Type quote here"
                    , onInput OnQuoteChange
                    ]
                    [ text form.quote ]
                , viewFieldError Quote_ validated
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-900 mt-2", for "author" ]
                    [ text "Author" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", fieldHasError Author validated ) ]
                    , id "author"
                    , value form.author
                    , placeholder "Author"
                    , type_ "text"
                    , onInput OnAuthorChange
                    ]
                    [ text form.author ]
                , viewFieldError Author validated
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-900 mt-2", for "reference" ]
                    [ text "Reference" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", fieldHasError Reference validated ) ]
                    , id "reference"
                    , value <| Maybe.withDefault "" form.reference
                    , placeholder "https://link-to-the-quote.com"
                    , type_ "text"
                    , onInput OnReferenceChange
                    ]
                    [ text <| Maybe.withDefault "" form.reference ]
                , viewFieldError Reference validated
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-900 mt-2", for "reference" ]
                    [ text "Tags" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , id "tags"
                    , value ""
                    , placeholder "e.g. Stoic"
                    , type_ "text"
                    , onInput OnTagsChange
                    ]
                    [ text form.author ]
                ]

            -- , viewFormServerError validated
            ]
        ]


viewFormServerError : Maybe Supabase.AuthError -> Html msg
viewFormServerError serverError =
    let
        message_ =
            serverError
                |> Maybe.map (\{ message } -> message)
                |> Maybe.withDefault ""
    in
    div [ class "h-1" ] [ p [ class "text-sm mt-3 text-red-500" ] [ text message_ ] ]


viewFieldError : Field -> Validated Problem ValidForm -> Html msg
viewFieldError field validated =
    case Validator.Named.getErrors (fieldToString field) validated of
        Nothing ->
            text ""

        Just errors ->
            div []
                (List.map
                    (\error ->
                        case error of
                            InvalidEntry _ message ->
                                div [ class "h-1" ] [ p [ class "text-sm mt-1 text-red-500" ] [ text message ] ]
                    )
                    errors
                )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- Supabase.quoteResponse GotQuotesResponse
