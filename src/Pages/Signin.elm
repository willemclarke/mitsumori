module Pages.Signin exposing (..)

import Components.Button as Button
import Html exposing (Html, a, div, form, header, input, label, text)
import Html.Attributes exposing (class, for, href, id, placeholder, type_)
import Html.Events exposing (onInput)



-- MODEL


type alias Model =
    { email : String
    , password : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { email = "", password = "" }, Cmd.none )



-- UPDATE


type Msg
    = OnEmailChange String
    | OnPasswordChange String
    | OnSubmit


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnEmailChange email ->
            ( { model | email = email }, Cmd.none )

        OnPasswordChange password ->
            ( { model | password = password }, Cmd.none )

        OnSubmit ->
            ( model, Cmd.none )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Login"
    , content = div [ class "mt-52" ] [ viewSigninForm model ]
    }


viewSigninForm : Model -> Html Msg
viewSigninForm model =
    div [ class "flex flex-col font-light text-black text-start lg:w-96 md:w-96 sm:w-40" ]
        [ header [ class "text-2xl mb-6 font-medium font-serif" ] [ text "Welcome back" ]
        , form [ id "signup-form" ]
            [ div [ class "flex flex-col my-2" ]
                [ label [ class "text-gray-900", for "email" ]
                    [ text "Email address" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline focus:outline-offset-1 focus:outline-2 focus:outline-gray-500"
                    , id "email"
                    , placeholder "your.email@address.com"
                    , type_ "text"
                    , onInput OnEmailChange
                    ]
                    [ text model.email ]
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-700", for "password" ]
                    [ text "Password (8+ chars)" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline focus:outline-offset-1 focus:outline-2 focus:outline-gray-500"
                    , id "password"
                    , placeholder "Choose your password"
                    , type_ "password"
                    , onInput OnPasswordChange
                    ]
                    [ text model.password ]
                ]
            ]
        , div [ class "flex mt-6 justify-between items-center" ]
            [ Button.create { label = "Sign in", onClick = OnSubmit } |> Button.view
            , a [ href "signup", class "text-gray-900 underline underline-offset-2" ] [ text "Or sign up" ]
            ]
        ]
