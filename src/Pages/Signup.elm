module Pages.Signup exposing (Model, Msg(..), init, subscriptions, update, view)

import Components.Button as Button
import Html exposing (Html, a, div, form, header, input, label, li, p, text, ul)
import Html.Attributes exposing (class, for, href, id, placeholder, type_, value)
import Html.Events exposing (onInput)
import Json.Decode as JD
import Json.Encode as JE
import Router.Route as Route
import Shared exposing (Shared, SharedUpdate(..))
import Supabase
import User



-- MODEL


type alias Model =
    { form : Form
    , problems : List Problem
    }


type SignupResponse
    = UserOk User.User
    | SignupError Supabase.Error
    | PayloadError


type Problem
    = InvalidEntry ValidatedField String
    | ServerError Supabase.Error



-- | Error Err


type alias Form =
    { email : String
    , username : String
    , password : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { form =
            { email = ""
            , username = ""
            , password = ""
            }
      , problems = []
      }
    , Cmd.none
    )


encodeForm : Form -> JE.Value
encodeForm { email, username, password } =
    JE.object
        [ ( "email", JE.string <| String.trim email )
        , ( "username", JE.string <| String.trim username )
        , ( "password", JE.string <| String.trim password )
        ]


signupResponseDecoder : JE.Value -> SignupResponse
signupResponseDecoder json =
    JD.decodeValue
        (JD.oneOf
            [ JD.map UserOk User.decoder, JD.map SignupError Supabase.errorDecoder ]
        )
        json
        |> Result.withDefault PayloadError



-- UPDATE


type Msg
    = OnEmailChange String
    | OnUsernameChange String
    | OnPasswordChange String
    | OnSubmit
    | GotSignupResponse JE.Value


update : Shared -> Msg -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
update shared msg model =
    case msg of
        OnEmailChange email ->
            updateForm (\form -> { form | email = email }) model

        OnUsernameChange username ->
            updateForm (\form -> { form | username = username }) model

        OnPasswordChange password ->
            updateForm (\form -> { form | password = password }) model

        OnSubmit ->
            case validateForm model.form of
                Ok validForm ->
                    ( { model | problems = [] }, Supabase.signUp (encodeForm validForm), Shared.NoUpdate )

                Err problems ->
                    ( { model | problems = problems }, Cmd.none, Shared.NoUpdate )

        GotSignupResponse json ->
            let
                signupResponse =
                    signupResponseDecoder json
            in
            case signupResponse of
                UserOk user ->
                    ( { model | form = emptyForm }
                    , Route.pushUrl shared.key Route.Home
                    , Shared.UpdateUser user
                    )

                SignupError error ->
                    let
                        x =
                            Debug.log "inside SignupError error" error

                        -- map Supabase.Error into the ServerError type so we can append to model
                        serverErrors =
                            List.map ServerError [ error ] |> Debug.log "serverErrors"
                    in
                    -- TODO: proper error handling
                    ( { model | problems = List.append model.problems serverErrors }, Cmd.none, Shared.NoUpdate )

                PayloadError ->
                    ( model, Cmd.none, Shared.NoUpdate )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none, Shared.NoUpdate )


emptyForm : Form
emptyForm =
    { email = "", username = "", password = "" }



-- FORM STUFF


type ValidatedField
    = Username
    | Email
    | Password


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Username
    , Email
    , Password
    ]


validateForm : Form -> Result (List Problem) Form
validateForm form =
    case List.concatMap (validateField form) fieldsToValidate of
        [] ->
            Ok form

        problems ->
            Err problems


validateField : Form -> ValidatedField -> List Problem
validateField form field =
    List.map (InvalidEntry field) <|
        case field of
            Email ->
                if String.isEmpty form.email then
                    [ "Email can't be blank." ]

                else
                    []

            Username ->
                if String.isEmpty form.username then
                    [ "Username can't be blank." ]

                else
                    []

            Password ->
                if String.isEmpty form.password then
                    [ "Password can't be blank." ]

                else if String.length form.password < 8 then
                    [ "Password must be at least 8 characters long." ]

                else
                    []



-- VIEW


view : Model -> Html Msg
view model =
    div [] [ viewSignupForm model.form model.problems ]


viewSignupForm : Form -> List Problem -> Html Msg
viewSignupForm form problems =
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
            , ul [ class "mt-3" ] (List.map viewProblem problems)
            ]
        , div [ class "flex mt-6 justify-between items-center" ]
            [ Button.create { label = "Create account", onClick = OnSubmit } |> Button.view
            , a [ href <| "signin", class "ml-2 text-gray-700 underline underline-offset-2" ] [ text "Or sign in" ]
            ]
        ]


viewProblem : Problem -> Html msg
viewProblem problem =
    let
        errorMsg =
            case problem of
                InvalidEntry _ string ->
                    string

                ServerError { msg } ->
                    msg
    in
    li [ class "mt-2 text-red-500" ] [ text errorMsg ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ Supabase.signUpResponse GotSignupResponse ]
