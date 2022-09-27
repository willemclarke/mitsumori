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
-- TODO: wrap email, username & password into Form type


type alias Model =
    { email : String
    , username : String
    , password : String
    , session : Session
    }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { email = "", username = "", password = "", session = session }, Cmd.none )


encodeUser : { email : String, username : String, password : String } -> JE.Value
encodeUser { email, username, password } =
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
            ( { model | email = email }, Cmd.none, [] )

        OnUsernameChange username ->
            ( { model | username = username }, Cmd.none, [] )

        OnPasswordChange password ->
            ( { model | password = password }, Cmd.none, [] )

        OnSubmit ->
            let
                user =
                    { email = model.email, username = model.username, password = model.password }
            in
            ( model
            , Supabase.signUp (encodeUser user)
            , []
            )

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


setSession : User -> Session -> Session
setSession user session =
    { session | user = user }



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Signup"
    , content = div [ class "mt-52" ] [ viewSignupForm model ]
    }


viewSignupForm : Model -> Html Msg
viewSignupForm model =
    div [ class "flex flex-col font-light text-black text-start lg:w-96 md:w-96 sm:w-40" ]
        [ header [ class "text-2xl mb-6 font-medium font-serif" ] [ text "Join mitsumori" ]
        , form [ id "signup-form" ]
            [ div [ class "flex flex-col my-2" ]
                [ label [ class "text-gray-900", for "email" ]
                    [ text "Email address" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , id "email"
                    , placeholder "your.email@address.com"
                    , type_ "text"
                    , value model.email
                    , onInput OnEmailChange
                    ]
                    [ text model.email ]
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-900", for "username" ]
                    [ text "Username" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , id "username"
                    , placeholder "johndoe"
                    , type_ "text"
                    , value model.username
                    , onInput OnUsernameChange
                    ]
                    [ text model.email ]
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-700", for "password" ]
                    [ text "Password (8+ chars)" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , id "password"
                    , placeholder "Choose your password"
                    , type_ "password"
                    , value model.password
                    , onInput OnPasswordChange
                    ]
                    [ text model.password ]
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
