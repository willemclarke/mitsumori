module Main exposing (main)

import Browser
import Html exposing (Html, div, form, img, input, text, textarea)
import Html.Attributes exposing (class, placeholder, src, style)
import Html.Events exposing (onInput, onSubmit)
import Json.Decode as JD
import Json.Encode as JE
import Ports


type alias Model =
    { inputQuote : String
    , quotes : List Quote
    }


type alias Quote =
    { quote : String
    }


quoteKey : String
quoteKey =
    "quotes"


init : () -> ( Model, Cmd Msg )
init _ =
    ( { inputQuote = "", quotes = [] }, Ports.getQuotes quoteKey )


type Msg
    = OnInput String
    | OnSubmit
    | RecievedQuotes ( Ports.Key, JD.Value )
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
            ( { model | inputQuote = "" }, Cmd.batch [ Ports.setQuote ( quoteKey, encodedQuote ), Ports.getQuotes quoteKey ] )

        RecievedQuotes ( _, _ ) ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [ class "flex justify-center h-full w-full" ]
        [ div [ class "w-full flex-col text-center justify-center" ]
            [ div [ class "w-full text-4xl mt-12" ] [ text "mitsumori" ]
            , viewForm model.inputQuote
            ]
        ]


viewForm : String -> Html Msg
viewForm inputtedQuote =
    div [ class "my-4" ]
        [ form [ class "w-full", onSubmit OnSubmit ]
            [ input [ class "mt-1 p-2 rounded shadow-l w-5/12", placeholder "Type quote here", onInput OnInput ] [ text inputtedQuote ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.getQuotesResponse RecievedQuotes ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
