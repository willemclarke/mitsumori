module Pages.Profile exposing (Model, Msg(..), init, update, view)

import Html exposing (Html, a, button, div, hr, input, label, p, span, text, textarea)
import Html.Attributes exposing (class, classList, for, href, id, maxlength, placeholder, rows, tabindex, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Shared exposing (Shared)


type alias Model =
    { title : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { title = "Test" }, Cmd.none )


type Msg
    = NoOp


update : Shared -> Msg -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
update shared msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none, Shared.NoUpdate )


view : Shared -> Model -> Html Msg
view shared model =
    div [ class "flex flex-col h-full w-full items-center" ]
        [ text model.title ]
