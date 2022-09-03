module Main exposing (main)

import Browser
import Browser.Dom as Dom
import Html exposing (Html, div, form, img, input, li, p, span, text, textarea, ul)
import Html.Attributes exposing (class, cols, id, placeholder, rows, src, style, value)
import Html.Events exposing (onInput, onSubmit)
import Json.Decode as JD
import Json.Encode as JE
import Ports
import Random exposing (Seed)
import Task
import Time exposing (Posix)
import Uuid exposing (Uuid)



-- MODEL


type alias Model =
    { inputQuote : String
    , quotes : List Quote
    , seed : Seed
    }


type alias Flags =
    { seed : Int
    }


type alias Quote =
    { quote : String
    , id : Uuid
    }


init : JE.Value -> ( Model, Cmd Msg )
init flagsValue =
    let
        decodedFlags =
            JD.decodeValue flagsDecoder flagsValue
    in
    case decodedFlags of
        Ok flags ->
            ( { inputQuote = "", quotes = [], seed = Random.initialSeed flags.seed }
            , Cmd.batch
                [ Ports.getQuotes ()
                , Dom.focus "quote-input" |> Task.attempt (always NoOp)
                ]
            )

        Err _ ->
            ( { inputQuote = "", quotes = [], seed = Random.initialSeed 0 }, Cmd.none )


quoteDecoder : JD.Decoder Quote
quoteDecoder =
    JD.map2 Quote
        (JD.field "quote" JD.string)
        (JD.field "id" Uuid.decoder)


quoteEncoder : { quote : String, id : Uuid } -> JE.Value
quoteEncoder { quote, id } =
    JE.object [ ( "quote", JE.string quote ), ( "id", Uuid.encode id ) ]


flagsDecoder : JD.Decoder Flags
flagsDecoder =
    JD.map Flags
        (JD.field "seed" JD.int)



-- UPDATE


type Msg
    = OnInput String
    | OnSubmit
    | RecievedQuotes JD.Value
    | NoOp


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        OnInput str ->
            ( { model | inputQuote = str }, Cmd.none )

        OnSubmit ->
            let
                uuid =
                    generateUuid model.seed
            in
            if String.isEmpty model.inputQuote then
                ( model, Cmd.none )

            else
                ( { model | inputQuote = "", seed = step model.seed }
                , Ports.setQuote <| quoteEncoder { quote = model.inputQuote, id = uuid }
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
    div [ class "flex justify-center h-full w-full" ]
        [ div [ class "flex-col text-center justify-center" ]
            [ div [ class "text-5xl mt-8" ] [ text "mitsumori" ]
            , div [ class "flex flex-col justify-center" ]
                [ viewForm model.inputQuote
                , viewQuotes model.quotes
                ]
            ]
        ]


viewForm : String -> Html Msg
viewForm inputtedQuote =
    div [ class "my-4" ]
        [ form [ onSubmit OnSubmit ]
            [ input
                [ class "mt-1 p-2 rounded shadow-l w-6/12"
                , placeholder "Type quote here"
                , onInput OnInput
                , value inputtedQuote
                , id "quote-input"
                ]
                [ text inputtedQuote ]
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
                [ text "--- Marcus Aurelius (Roman Philosopher)" ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.getQuotesResponse RecievedQuotes


main : Program JE.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
