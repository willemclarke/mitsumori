module Pages.Home exposing (Model, Msg(..), init, subscriptions, update, view)

import Components.Button as Button
import Components.Modal as Modal
import Html exposing (Html, div, form, input, label, p, text, ul)
import Html.Attributes exposing (class, for, id, placeholder, type_, value)
import Html.Events exposing (onInput)
import Html.Extra as HE
import Json.Decode as JD
import Json.Encode as JE
import Random exposing (Seed)
import Shared exposing (Shared)
import Uuid exposing (Uuid)



-- MODEL


type alias Model =
    { inputQuote : String
    , inputAuthor : String
    , quotes : List Quote
    , modalState : ModalState
    }


type alias Quote =
    { quote : String
    , author : String
    , id : Uuid
    }


type ModalState
    = Visible
    | Hidden


init : () -> ( Model, Cmd Msg )
init _ =
    ( { inputQuote = "", inputAuthor = "", quotes = [], modalState = Hidden }, Cmd.none )


quoteDecoder : JD.Decoder Quote
quoteDecoder =
    JD.map3 Quote
        (JD.field "quote" JD.string)
        (JD.field "author" JD.string)
        (JD.field "id" Uuid.decoder)


quoteEncoder : Quote -> JE.Value
quoteEncoder { quote, author, id } =
    JE.object
        [ ( "quote", JE.string quote )
        , ( "author", JE.string author )
        , ( "id", Uuid.encode id )
        ]



-- UPDATE


type Msg
    = OnQuoteChange String
    | OnAuthorChange String
    | OnSubmit
    | RecievedQuotes JD.Value
    | AddQuoteOnClick
    | CloseModal
    | NoOp


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        OnQuoteChange str ->
            ( { model | inputQuote = str }, Cmd.none )

        OnAuthorChange str ->
            ( { model | inputAuthor = str }, Cmd.none )

        AddQuoteOnClick ->
            ( { model | modalState = Visible }, Cmd.none )

        CloseModal ->
            ( { model | modalState = Hidden }, Cmd.none )

        OnSubmit ->
            -- let
            -- uuid =
            --     generateUuid session.seed
            -- in
            if String.isEmpty model.inputQuote && String.isEmpty model.inputAuthor then
                ( model, Cmd.none )

            else
                ( { model | inputQuote = "", modalState = Hidden }
                , Cmd.none
                )

        RecievedQuotes value ->
            let
                decodedQuotes =
                    JD.decodeValue (quoteDecoder |> JD.list) value
            in
            case decodedQuotes of
                Ok quotes ->
                    ( { model | quotes = quotes }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


generateUuid : Seed -> Uuid
generateUuid seed =
    Tuple.first <| Random.step Uuid.uuidGenerator seed


step : Seed -> Seed
step =
    Tuple.second << Random.step (Random.int Random.minInt Random.maxInt)



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "flex flex-col justify-center" ]
        [ addQuoteButton model.inputQuote model.modalState
        , viewQuotes model.quotes
        ]


addQuoteButton : String -> ModalState -> Html Msg
addQuoteButton inputtedQuote modalState =
    div [ class "my-4" ]
        [ Button.create { label = "Add Quote", onClick = AddQuoteOnClick } |> Button.view
        , viewAddQuoteModal inputtedQuote modalState
        ]


viewAddQuoteModal : String -> ModalState -> Html Msg
viewAddQuoteModal inputtedQuote modalState =
    case modalState of
        Visible ->
            Modal.create
                { title = "Add quote"
                , body = modalBody inputtedQuote
                , actions =
                    Modal.acceptAndDiscardActions (Modal.basicAction "Add quote" OnSubmit) (Modal.basicAction "Cancel" CloseModal)
                }
                |> Modal.view

        Hidden ->
            HE.nothing


modalBody : String -> Html Msg
modalBody inputtedQuote =
    div [ class "flex flex-col text-black" ]
        [ form [ id "add-quote-form" ]
            [ div [ class "flex flex-col my-2" ]
                [ label [ for "quote" ]
                    [ text "Quote body" ]
                , input
                    [ class "mt-2 p-2 border-2 border-black rounded shadow-l"
                    , id "quote"
                    , placeholder "Type quote here"
                    , type_ "text"
                    , onInput OnQuoteChange
                    ]
                    [ text inputtedQuote ]
                ]
            , div [ class "flex flex-col mt-3" ]
                [ label [ for "author" ]
                    [ text "Author" ]
                , input
                    [ class "mt-2 p-2 border-2 border-black rounded shadow-l"
                    , id "author"
                    , placeholder "Author"
                    , type_ "text"
                    , onInput OnAuthorChange
                    ]
                    [ text inputtedQuote ]
                ]
            ]
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
                [ text <| "---" ++ quote.author ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
