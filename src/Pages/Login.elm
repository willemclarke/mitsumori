module Pages.Login exposing (..)

import Html exposing (Html, div, text)



-- MODEL


type alias Model =
    { username : String
    , password : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { username = "", password = "" }, Cmd.none )



-- UPDATE


type Msg
    = OnUsernameChange
    | OnPasswordChange


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnUsernameChange ->
            ( model, Cmd.none )

        OnPasswordChange ->
            ( model, Cmd.none )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view _ =
    { title = "Login"
    , content = div [] [ text "Login page" ]
    }
