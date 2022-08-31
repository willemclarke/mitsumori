module Main exposing (main)

import Browser
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, src, style)


type alias Model =
    { quote : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { quote = "" }, Cmd.none )


type Msg
    = OnInput String


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        OnInput _ ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [ class "flex justify-center h-full w-full" ]
        [ div [ class "w-full flex-col text-center" ]
            [ div [ class "text-4xl my-12" ] [ text "mitsumori" ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
