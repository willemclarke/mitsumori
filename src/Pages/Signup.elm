module Pages.Signup exposing (..)

import Actions exposing (Actions)
import Components.Button as Button
import Html exposing (Html, a, div, form, header, input, label, text)
import Html.Attributes exposing (class, for, href, id, placeholder, type_, value)
import Html.Events exposing (onInput)
import Json.Decode as JD
import Json.Encode as JE
import Route
import Session exposing (Session)
import Supabase
import User exposing (User)



-- MODEL


type alias Model =
    { session : Session
    , form : Form
    }


type alias Form =
    { email : String
    , username : String
    , password : String
    }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , form =
            { email = ""
            , username = ""
            , password = ""
            }
      }
    , Cmd.none
    )


encodeForm : Form -> JE.Value
encodeForm { email, username, password } =
    JE.object
        [ ( "email", JE.string email )
        , ( "username", JE.string username )
        , ( "password", JE.string password )
        ]



-- UPDATE


type Msg
    = OnEmailChange String
    | OnUsernameChange String
    | OnPasswordChange String
    | OnSubmit
    | GotSignupResponse JE.Value


update : Msg -> Model -> ( Model, Cmd Msg, List Actions )
update msg model =
    let
        session =
            model.session
    in
    case msg of
        OnEmailChange email ->
            updateForm (\form -> { form | email = email }) model

        OnUsernameChange username ->
            updateForm (\form -> { form | username = username }) model

        OnPasswordChange password ->
            updateForm (\form -> { form | password = password }) model

        OnSubmit ->
            ( model, Supabase.signUp (encodeForm model.form), [] )

        GotSignupResponse json ->
            let
                decoded =
                    JD.decodeValue User.decoder json
            in
            case decoded of
                Ok user ->
                    ( model, Route.pushUrl session.key Route.Home, [ Actions.SetSession <| setSession user session ] )

                Err err ->
                    let
                        error =
                            Debug.log "Err" err
                    in
                    ( model, Cmd.none, [] )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg, List Actions )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none, [] )


setSession : User -> Session -> Session
setSession user session =
    { session | user = user }



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Signup"
    , content = div [ class "mt-52" ] [ viewSignupForm model.form ]
    }


viewSignupForm : Form -> Html Msg
viewSignupForm form =
    div [ class "flex flex-col font-light text-black text-start lg:w-96 md:w-96 sm:w-40" ]
        [ header [ class "text-2xl mb-6 font-medium font-serif" ] [ text "Join mitsumori" ]
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
                [ label [ class "text-gray-900", for "username" ]
                    [ text "Username" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , id "username"
                    , placeholder "johndoe"
                    , type_ "text"
                    , value form.username
                    , onInput OnUsernameChange
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
            [ Button.create { label = "Create account", onClick = OnSubmit } |> Button.view
            , a [ href <| Route.toString Route.Signin, class "ml-2 text-gray-700 underline underline-offset-2" ] [ text "Or sign in" ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ Supabase.signUpResponse GotSignupResponse ]
