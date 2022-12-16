module Pages.Home exposing (Model, Msg(..), init, subscriptions, update, view)

import Components.Icons as Icons
import Components.Modal as Modal
import Components.Spinner as Spinner
import Components.Toast as Toast
import Debounce exposing (Debounce)
import Dict
import Graphql.Http
import Html exposing (Html, a, button, div, hr, input, label, p, span, text, textarea)
import Html.Attributes exposing (class, classList, for, href, id, maxlength, placeholder, rows, tabindex, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Extra as HE
import RemoteData exposing (RemoteData(..))
import Routing.Route as Route
import Shared exposing (Shared)
import Supabase
import Task
import User
import Validator
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
    , tags : String
    }


type alias ValidForm =
    { quote : String
    , author : String
    , reference : Maybe String
    , tags : String
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
      , modalForm = { quote = "", author = "", reference = Nothing, tags = "" }
      , modalFormProblems = []
      , modalIsLoading = False
      , modalType = NewQuote
      , modalVisibility = Hidden
      , validated = Err Dict.empty
      }
    , Supabase.getQuotes (GotQuotesResponse None) shared
    )



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
    | GotQuotesResponse Action QuotesResponse
    | GotQuoteTagsResponse Action (RemoteData (Graphql.Http.Error (List Supabase.Tag)) (List Supabase.Tag))
    | GotInsertQuoteResponse (RemoteData (Graphql.Http.Error (List Supabase.Quote)) (List Supabase.Quote))
    | GotDeleteQuoteResponse (RemoteData (Graphql.Http.Error (List Supabase.Quote)) (List Supabase.Quote))
    | GotEditQuotesResponse String (RemoteData (Graphql.Http.Error (List Supabase.Quote)) (List Supabase.Quote))
    | NoOp



{-
   This type is for the GotQuoteTagsResponse & GotQuotesResponse Msgs:
        We want to know whether a quote was deleted, edited, added so
        a respective toast can be displayed if request is successful.
-}


type Action
    = AddQuote
    | EditQuote
    | DeleteQuote
    | None


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

        OnTagsChange tags ->
            updateModalForm (\form -> { form | tags = tags }) model

        {- If we edit a quote, update the modalForm with the quotes values, also pass the Quote to the `Editing`
           constructor so when we submit the modal, we have the ID of the quote for supabase to use.
        -}
        OpenEditQuoteModal quote ->
            ( { model
                | modalForm =
                    { quote = quote.quote
                    , author = quote.author
                    , reference = quote.reference
                    , tags = ""
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
                            }
                    in
                    ( { model | validated = validatedForm, modalIsLoading = True }
                    , Supabase.editQuote (GotEditQuotesResponse quote.id) quote_ shared
                    , Shared.NoUpdate
                    )

                Err _ ->
                    ( { model | validated = validatedForm }, Cmd.none, Shared.NoUpdate )

        SubmitDeleteQuoteModal quoteId ->
            ( { model | modalIsLoading = True, modalForm = emptyModalForm }
            , Supabase.deleteQuote GotDeleteQuoteResponse quoteId shared
            , Shared.NoUpdate
            )

        GotQuotesResponse action quotesResponse ->
            ( { model | quotes = quotesResponse }, Cmd.none, toastFromAction action )

        -- TODO: handle case of error here better via toasts
        GotInsertQuoteResponse quotesResponse ->
            case quotesResponse of
                RemoteData.Success quotes ->
                    let
                        tags =
                            model.modalForm.tags

                        {- Have to get the head of the list as insertQuotes returns the quote in a list ^__^ -}
                        quoteId =
                            List.head quotes
                                |> Maybe.map (\quote -> quote.id)
                                |> Maybe.withDefault ""

                        ( model_, cmd_, shared_ ) =
                            if String.isEmpty tags then
                                ( { model | modalIsLoading = False, modalVisibility = Hidden, modalType = NewQuote }
                                , Supabase.getQuotes (GotQuotesResponse AddQuote) shared
                                , Shared.NoUpdate
                                )

                            else
                                ( model
                                , Supabase.insertQuoteTags (GotQuoteTagsResponse AddQuote) { quoteId = quoteId, tags = stringTagsToList tags } shared
                                , Shared.NoUpdate
                                )
                    in
                    ( model_, cmd_, shared_ )

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

        GotEditQuotesResponse quoteId quotesResponse ->
            case quotesResponse of
                RemoteData.Success _ ->
                    let
                        tags =
                            model.modalForm.tags

                        ( model_, cmd_, shared_ ) =
                            if String.isEmpty tags then
                                ( { model | modalIsLoading = False, modalVisibility = Hidden, modalType = NewQuote, modalForm = emptyModalForm }
                                , Supabase.getQuotes (GotQuotesResponse EditQuote) shared
                                , Shared.NoUpdate
                                )

                            else
                                ( model
                                , Supabase.insertQuoteTags (GotQuoteTagsResponse EditQuote) { quoteId = quoteId, tags = stringTagsToList tags } shared
                                , Shared.NoUpdate
                                )
                    in
                    ( model_, cmd_, shared_ )

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

        GotQuoteTagsResponse action response ->
            case response of
                RemoteData.Success _ ->
                    ( { model | modalVisibility = Hidden, modalType = NewQuote, modalIsLoading = False, modalForm = emptyModalForm }
                    , Supabase.getQuotes (GotQuotesResponse action) shared
                    , Shared.NoUpdate
                    )

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

        GotDeleteQuoteResponse quotesResponse ->
            case quotesResponse of
                RemoteData.Success _ ->
                    ( { model | modalVisibility = Hidden, modalType = NewQuote, modalIsLoading = False }
                    , Supabase.getQuotes (GotQuotesResponse DeleteQuote) shared
                    , Shared.NoUpdate
                    )

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

        NoOp ->
            ( model, Cmd.none, Shared.NoUpdate )


updateFilter : Maybe String -> Route.Filter -> Route.Filter
updateFilter searchTerm filter =
    { filter | searchTerm = searchTerm }


emptyModalForm : ModalForm
emptyModalForm =
    { quote = "", author = "", reference = Nothing, tags = "" }


updateModalForm : (ModalForm -> ModalForm) -> Model -> ( Model, Cmd msg, Shared.SharedUpdate )
updateModalForm transform model =
    ( { model | modalForm = transform model.modalForm }, Cmd.none, Shared.NoUpdate )


toastFromAction : Action -> Shared.SharedUpdate
toastFromAction action =
    case action of
        AddQuote ->
            Shared.ShowToast (Toast.Success "Quote added successfully.")

        EditQuote ->
            Shared.ShowToast (Toast.Success "Quote edited successfully.")

        DeleteQuote ->
            Shared.ShowToast (Toast.Success "Quote deleted successfully.")

        None ->
            Shared.NoUpdate



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
        |> Validator.Named.validate (fieldToString Tags) (validateTags (InvalidEntry Tags "Tags must be separated by commas")) trimmedForm.tags



{-
   Some bootleg validaiton for tags as I can't be bothered making a combobox:
       - Tags are just a string of words which have to separated by a comma
           - Split string into words, if there is more than one tag,
             map over tags, making sure they're split by comma, if they don't all pass show error
           - If only one tag, return true so user doesn't have to append comma to single tag
-}


validateTags : error -> Validator.Validator error String String
validateTags errorMsg =
    Validator.customValidator errorMsg
        (\tags ->
            if List.length (String.words tags) > 1 then
                String.words tags
                    |> List.map (\word -> String.contains "," word)
                    |> List.all (\bool -> bool)

            else
                True
        )


supabaseTagsToString : List Supabase.Tag -> List String
supabaseTagsToString tags =
    List.map (\tag -> tag.text) tags



{-
   "stoic, roman, plato," == ["stoic", "roman", "plato"]
-}


stringTagsToList : String -> List String
stringTagsToList tags =
    tags
        |> String.split ","
        |> List.map String.trim
        |> List.filter (\tag -> not (String.isEmpty tag))


fieldHasError : Field -> Validated Problem ValidForm -> Bool
fieldHasError field validated =
    Validator.Named.hasErrorsOn (fieldToString field) validated


trimFields : ModalForm -> ModalForm
trimFields form =
    { quote = String.trim form.quote
    , author = String.trim form.author
    , reference = Maybe.map (\ref -> String.trim ref) form.reference
    , tags = String.trim form.tags
    }



-- VIEW


view : Shared -> Model -> Html Msg
view shared model =
    div
        [ class "flex flex-col h-full w-full items-center" ]
        [ viewHeader model.modalForm model.validated model.modalType model.modalVisibility model.modalIsLoading
        , viewQuotes model.quotes shared
        ]


viewHeader : ModalForm -> Validated Problem ValidForm -> ModalType -> ModalVisibility -> Bool -> Html Msg
viewHeader form validated modalType visibility isLoading =
    div [ class "flex flex-col" ]
        [ addQuoteButton form validated modalType visibility isLoading
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
                    div [ class "grid grid-rows-4 sm:grid-cols-1 lg:grid-cols-3 gap-x-6 gap-y-2" ]
                        (List.map (\quote -> viewQuote shared quote) quotes.quotes)

                _ ->
                    HE.nothing
    in
    div [ class "mt-12 text-start px-6 md:px-12 lg:px-16 xl:px-16 2xl:px-18 h-full w-full" ] [ content ]


viewQuote : Shared -> Supabase.Quote -> Html Msg
viewQuote shared quote =
    let
        quoteTags =
            List.map (\tag -> viewQuoteTag tag.text) quote.tags

        reference =
            Maybe.withDefault "" quote.reference

        viewQuoteReference =
            if String.isEmpty reference then
                HE.nothing

            else
                a [ href <| reference, class "text-gray-600 text-sm cursor-pointer hover:text-black", target "_blank" ] [ text "Quote reference" ]
    in
    div
        [ class "flex flex-col h-fit border rounded-lg p-6 shadow-sm hover:bg-gray-100/30 transition ease-in-out hover:-translate-y-px duration-300"
        , tabindex 0
        ]
        [ p [ class "text-lg text-gray-800" ] [ text quote.quote ]
        , p [ class "mt-1 text-gray-600 text-md font-light" ] [ text <| "by " ++ quote.author ]
        , hr [ class "bg-gray-600 my-2" ] []
        , div [ class "flex flex-col" ]
            [ div [ class "flex space-x-2 my-2" ] quoteTags
            , viewQuoteReference
            ]
        , viewEditAndDeleteIconButtons shared quote
        , p [ class "text-gray-600 text-sm cursor-pointer mt-2" ]
            [ text <| "Posted by "
            , span [ class "hover:text-black" ] [ text <| User.username shared.user ]
            ]

        -- This will become a tag once profile table/page setup
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
        div [ class "flex justify-between mt-2" ]
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
                    , placeholder "https://www.link-to-the-quote.com"
                    , type_ "text"
                    , onInput OnReferenceChange
                    ]
                    [ text <| Maybe.withDefault "" form.reference ]
                , viewFieldError Reference validated
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-900 mt-2", for "reference" ]
                    [ text "Tags (separated by comma)" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", fieldHasError Tags validated ) ]
                    , id "tags"
                    , value form.tags
                    , placeholder "stoic, roman, plato,"
                    , type_ "text"
                    , onInput OnTagsChange
                    ]
                    [ text form.author ]
                , viewFieldError Tags validated
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
            HE.nothing

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
