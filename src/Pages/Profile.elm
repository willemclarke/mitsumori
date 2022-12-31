module Pages.Profile exposing (Model, Msg(..), init, subscriptions, update, view)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Html.Events
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
    div [ class "flex flex-col h-full w-full items-center mt-12" ]
        [ text model.title ]


subscriptions : Sub Msg
subscriptions =
    Sub.none
