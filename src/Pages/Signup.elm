module Pages.Signup exposing (Model, Msg(..), init, subscriptions, update, view)

import Components.Button as Button
import Dict
import Html exposing (Html, a, button, div, form, header, input, label, p, text)
import Html.Attributes exposing (class, classList, for, id, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Extra as HE
import Json.Decode as JD
import Json.Encode as JE
import Routing.Route as Route
import Shared exposing (Shared, SharedUpdate(..))
import Supabase
import User
import Validator.Named exposing (Validated)
import Validator.String



-- MODEL


type alias Model =
    { form : Form
    , validated : Validated Problem ValidForm
    , isLoading : Bool
    , serverError : Maybe Supabase.AuthError
    }


type alias Form =
    { email : String
    , username : String
    , password : String
    }


type alias ValidForm =
    { email : String, username : String, password : String }


type Problem
    = InvalidEntry Field String
    | ServerError Supabase.AuthError


type Field
    = Username
    | Email
    | Password


type SignupResponse
    = UserOk User.User
    | SignupError Supabase.AuthError
    | PayloadError


init : () -> ( Model, Cmd Msg )
init _ =
    ( { form =
            { email = ""
            , username = ""
            , password = ""
            }
      , validated = Err Dict.empty
      , isLoading = False
      , serverError = Nothing
      }
    , Cmd.none
    )


encodeForm : ValidForm -> JE.Value
encodeForm form =
    JE.object
        [ ( "email", JE.string form.email )
        , ( "username", JE.string form.username )
        , ( "password", JE.string form.password )
        ]


signupResponseDecoder : JE.Value -> SignupResponse
signupResponseDecoder json =
    JD.decodeValue
        (JD.oneOf
            [ JD.map UserOk User.decoder, JD.map SignupError Supabase.authErrorDecoder ]
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
    | NavigateTo Route.Route


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
            let
                validatedForm =
                    validateForm model.form
            in
            case validatedForm of
                Ok validForm ->
                    ( { model | validated = validatedForm, isLoading = True }, Supabase.signUp (encodeForm validForm), Shared.NoUpdate )

                Err _ ->
                    ( { model | validated = validatedForm }, Cmd.none, Shared.NoUpdate )

        GotSignupResponse json ->
            let
                signupResponse =
                    signupResponseDecoder json
            in
            case signupResponse of
                UserOk user ->
                    ( { model | form = emptyForm, isLoading = False }, Route.pushUrl shared.key (Route.Home Route.emptyFilter), Shared.UpdateUser user )

                SignupError error ->
                    ( { model | isLoading = False, serverError = Just error }, Cmd.none, Shared.NoUpdate )

                PayloadError ->
                    ( model, Cmd.none, Shared.NoUpdate )

        NavigateTo route ->
            ( model, Route.pushUrl shared.key route, Shared.NoUpdate )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none, Shared.NoUpdate )


emptyForm : Form
emptyForm =
    { email = "", username = "", password = "" }



-- FORM HELPERS


fieldToString : Field -> String
fieldToString field =
    case field of
        Email ->
            "email"

        Username ->
            "username"

        Password ->
            "password"


validateForm : Form -> Validated Problem ValidForm
validateForm form =
    let
        trimmedForm =
            trimFields form
    in
    Ok ValidForm
        |> Validator.Named.validateMany (fieldToString Email)
            [ Validator.String.notEmpty (InvalidEntry Email "Email can't be blank")
            , Validator.String.isEmail (InvalidEntry Email "Must be a valid email")
            ]
            trimmedForm.email
        |> Validator.Named.validate (fieldToString Username) (Validator.String.notEmpty (InvalidEntry Username "Username can't be blank")) trimmedForm.username
        |> Validator.Named.validateMany (fieldToString Password)
            [ Validator.String.notEmpty (InvalidEntry Password "Password can't be blank")
            , Validator.String.minLength (InvalidEntry Password "Password must be atleast 8 characters long") 8
            , Validator.String.hasLetter (InvalidEntry Password "Password must contain letters")
            , Validator.String.hasNumber (InvalidEntry Password "Password must contain numbers")
            ]
            trimmedForm.password


fieldHasError : Field -> Validated Problem ValidForm -> Bool
fieldHasError field validated =
    Validator.Named.hasErrorsOn (fieldToString field) validated


trimFields : Form -> Form
trimFields form =
    { username = String.trim form.username
    , email = String.trim form.email
    , password = String.trim form.password
    }



-- VIEW


view : Model -> Html Msg
view { form, validated, isLoading, serverError } =
    div [] [ viewSignupForm form validated serverError isLoading ]


viewSignupForm : Form -> Validated Problem ValidForm -> Maybe Supabase.AuthError -> Bool -> Html Msg
viewSignupForm form validated serverError isLoading =
    div [ class "flex flex-col font-light text-black text-start lg:w-96 md:w-96 sm:w-40" ]
        [ header [ class "text-2xl mb-6 font-medium font-serif" ] [ text "Join mitsumori" ]
        , Html.form [ id "signup-form" ]
            [ div [ class "flex flex-col mt-2" ]
                [ label [ class "text-gray-900", for "email" ]
                    [ text "Email address" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", fieldHasError Email validated ) ]
                    , id "email"
                    , placeholder "your.email@address.com"
                    , type_ "text"
                    , value form.email
                    , onInput OnEmailChange
                    ]
                    [ text form.email ]
                , viewFormErrors Email validated
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-900 mt-2", for "username" ]
                    [ text "Username" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", fieldHasError Username validated ) ]
                    , id "username"
                    , placeholder "johndoe"
                    , type_ "text"
                    , value form.username
                    , onInput OnUsernameChange
                    ]
                    [ text form.email ]
                , viewFormErrors Username validated
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-700 mt-2", for "password" ]
                    [ text "Password (8+ chars)" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", fieldHasError Password validated ) ]
                    , id "password"
                    , placeholder "Choose your password"
                    , type_ "password"
                    , value form.password
                    , onInput OnPasswordChange
                    ]
                    [ text form.password ]
                , viewFormErrors Password validated
                ]
            , viewFormServerError serverError
            ]
        , div [ class "flex mt-9 justify-between items-center" ]
            [ Button.create { label = "Create account", onClick = OnSubmit }
                |> Button.withIsLoading isLoading
                |> Button.view
            , button [ onClick <| NavigateTo Route.Signin, class "ml-2 text-gray-700 underline underline-offset-2 hover:text-black transition ease-in-out hover:-translate-y-0.5 duration-300s" ] [ text "Or sign in" ]
            ]
        ]


viewFormServerError : Maybe Supabase.AuthError -> Html msg
viewFormServerError serverError =
    let
        message_ =
            serverError
                |> Maybe.map (\{ message } -> message)
                |> Maybe.withDefault ""
    in
    div [ class "h-1" ] [ p [ class "text-sm mt-3 text-red-500" ] [ text message_ ] ]


viewFormErrors : Field -> Validated Problem ValidForm -> Html msg
viewFormErrors field validated =
    case Validator.Named.getErrors (fieldToString field) validated of
        Nothing ->
            text ""

        Just errors ->
            div []
                (List.map
                    (\error ->
                        case error of
                            InvalidEntry _ message ->
                                div [ class "h-1" ] [ p [ class "text-sm mt-1 text-red-500" ] [ text message ] ]

                            _ ->
                                HE.nothing
                    )
                    errors
                )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Supabase.signUpResponse GotSignupResponse
