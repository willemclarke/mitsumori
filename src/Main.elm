module Main exposing (main)

import Browser
import DataStore
import Html exposing (Html, div, form, img, input, li, text, textarea, ul)
import Html.Attributes exposing (class, placeholder, src, style, value)
import Html.Attributes.Extra as HAE
import Html.Events exposing (onInput, onSubmit)
import Json.Decode as JD
import Json.Encode as JE


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
    ( { inputQuote = "", quotes = [] }, DataStore.getQuotes quoteKey )


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
                ( { model | inputQuote = "" }, Cmd.batch [ DataStore.setQuote ( quoteKey, encodedQuote ), DataStore.getQuotes quoteKey ] )

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
        [ div [ class "w-full flex-col text-center justify-center" ]
            [ div [ class "w-full text-5xl mt-12" ] [ text "mitsumori" ]
            , viewForm model.inputQuote
            , viewQuotes model.quotes
            ]
        ]


viewForm : String -> Html Msg
viewForm inputtedQuote =
    div [ class "my-4" ]
        [ form [ class "w-full", onSubmit OnSubmit ]
            [ input
                [ class "mt-1 p-2 rounded shadow-l w-5/12"
                , placeholder "Type quote here"
                , onInput OnInput
                , value inputtedQuote
                ]
                [ text inputtedQuote ]
            ]
        ]


viewQuotes : List Quote -> Html msg
viewQuotes quotes =
    let
        mappedQuotes =
            List.map (\quote -> li [] [ text quote.quote ]) quotes
    in
    div [ class "my-6" ]
        [ ul [] mappedQuotes
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ DataStore.getQuotesResponse RecievedQuotes ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
