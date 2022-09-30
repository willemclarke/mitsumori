module Pages.Signin exposing (Model, Msg(..), init, subscriptions, update, view)

import Components.Button as Button
import Html exposing (Html, a, div, form, header, input, label, text)
import Html.Attributes exposing (class, for, href, id, placeholder, type_, value)
import Html.Events exposing (onInput)
import Json.Decode as JD
import Json.Encode as JE
import Router.Route as Route
import Shared exposing (Shared)
import Supabase
import User



-- MODEL


type alias Model =
    { form : Form
    }


type alias Form =
    { email : String
    , password : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { form =
            { email = ""
            , password = ""
            }
      }
    , Cmd.none
    )


encodeForm : Form -> JE.Value
encodeForm { email, password } =
    JE.object
        [ ( "email", JE.string <| String.trim email )
        , ( "password", JE.string <| String.trim password )
        ]



-- UPDATE


type Msg
    = OnEmailChange String
    | OnPasswordChange String
    | OnSubmit
    | GotSigninResponse JE.Value


update : Shared -> Msg -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
update shared msg model =
    case msg of
        OnEmailChange email ->
            updateForm (\form -> { form | email = email }) model

        OnPasswordChange password ->
            updateForm (\form -> { form | password = password }) model

        OnSubmit ->
            ( model, Supabase.signIn (encodeForm model.form), Shared.NoUpdate )

        GotSigninResponse json ->
            let
                decoded =
                    JD.decodeValue User.decoder json
            in
            case decoded of
                Ok user ->
                    ( { model | form = emptyForm }
                    , Route.pushUrl shared.key Route.Home
                    , Shared.UpdateUser user
                    )

                Err err ->
                    -- TODO: handle form server errors here
                    let
                        error =
                            Debug.log "Err" err
                    in
                    ( model, Cmd.none, Shared.NoUpdate )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none, Shared.NoUpdate )


emptyForm : Form
emptyForm =
    { email = "", password = "" }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mt-52" ] [ viewSigninForm model.form ]


viewSigninForm : Form -> Html Msg
viewSigninForm form =
    div [ class "flex flex-col font-light text-black text-start lg:w-96 md:w-96 sm:w-40" ]
        [ header [ class "text-2xl mb-6 font-medium font-serif" ] [ text "Welcome back" ]
        , Html.form [ id "signup-form" ]
            [ div [ class "flex flex-col my-2" ]
                [ label [ class "text-gray-900", for "email" ]
                    [ text "Email address" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , id "email"
                    , placeholder "your.email@address.com"
                    , type_ "text"
                    , value form.email
                    , onInput OnEmailChange
                    ]
                    [ text form.email ]
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-700", for "password" ]
                    [ text "Password (8+ chars)" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , id "password"
                    , placeholder "Choose your password"
                    , type_ "password"
                    , value form.password
                    , onInput OnPasswordChange
                    ]
                    [ text form.password ]
                ]
            ]
        , div [ class "flex mt-6 justify-between items-center" ]
            [ Button.create { label = "Sign in", onClick = OnSubmit } |> Button.view
            , a [ href <| "signup", class "text-gray-700 underline underline-offset-2" ] [ text "Or sign up" ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ Supabase.signInResponse GotSigninResponse ]
