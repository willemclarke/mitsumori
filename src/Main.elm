module Main exposing (main)

import Browser
import Browser.Dom as Dom
import DataStore
import Html exposing (Html, div, form, img, input, li, p, span, text, textarea, ul)
import Html.Attributes exposing (class, cols, id, placeholder, rows, src, style, value)
import Html.Events exposing (onInput, onSubmit)
import Json.Decode as JD
import Json.Encode as JE
import Task
import Time exposing (Posix)


type alias Model =
    { inputQuote : String
    , quotes : List Quote
    }


type alias Quote =
    { quote : String
    }


quoteDecoder : JD.Decoder Quote
quoteDecoder =
    JD.map Quote
        (JD.field "quote" JD.string)


quoteKey : String
quoteKey =
    "quotes"


init : () -> ( Model, Cmd Msg )
init _ =
    ( { inputQuote = "", quotes = [] }
    , Cmd.batch
        [ DataStore.getQuotes quoteKey
        , Dom.focus "quote-input" |> Task.attempt (always NoOp)
        ]
    )


type Msg
    = OnInput String
    | OnSubmit
    | RecievedQuotes ( DataStore.Key, JD.Value )
    | NoOp


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        OnInput str ->
            ( { model | inputQuote = str }, Cmd.none )

        OnSubmit ->
            let
                encodedQuote =
                    JE.object [ ( "quote", JE.string model.inputQuote ) ]
            in
            if String.isEmpty model.inputQuote then
                ( model, Cmd.none )

            else
                ( { model | inputQuote = "" }, Cmd.batch [ DataStore.setQuote ( quoteKey, encodedQuote ) ] )

        RecievedQuotes ( _, value ) ->
            let
                decodedQuotes =
                    JD.decodeValue (quoteDecoder |> JD.list) value
            in
            case decodedQuotes of
                Ok quotes ->
                    ( { model | quotes = List.reverse quotes }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


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
    div [ class "mx-6 max-w-3xl text-start" ]
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
    DataStore.getQuotesResponse RecievedQuotes


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
