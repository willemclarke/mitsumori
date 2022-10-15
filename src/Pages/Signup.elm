module Pages.Signup exposing (Model, Msg(..), init, subscriptions, update, view)

import Components.Button as Button
import Html exposing (Html, a, button, div, form, header, input, label, p, text)
import Html.Attributes exposing (class, classList, for, href, id, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
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
    , isLoading : Bool
    }


type alias Form =
    { email : String
    , username : String
    , password : String
    }


type Problem
    = InvalidEntry ValidatedField String
    | ServerError Supabase.AuthError


type ValidatedField
    = Username
    | Email
    | Password


type TrimmedForm
    = Trimmed Form


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
      , problems = []
      , isLoading = False
      }
    , Cmd.none
    )


encodeForm : TrimmedForm -> JE.Value
encodeForm (Trimmed form) =
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
            case validateForm model.form of
                Ok validForm ->
                    ( { model | problems = [], isLoading = True }, Supabase.signUp (encodeForm validForm), Shared.NoUpdate )

                Err problems ->
                    ( { model | problems = problems }, Cmd.none, Shared.NoUpdate )

        GotSignupResponse json ->
            let
                signupResponse =
                    signupResponseDecoder json
            in
            case signupResponse of
                UserOk user ->
                    ( { model | form = emptyForm, isLoading = False }, Route.pushUrl shared.key Route.Home, Shared.UpdateUser user )

                SignupError error ->
                    let
                        serverErrors =
                            List.map ServerError [ error ]
                    in
                    ( { model | isLoading = False, problems = List.append model.problems serverErrors }, Cmd.none, Shared.NoUpdate )

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


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Username
    , Email
    , Password
    ]


validateForm : Form -> Result (List Problem) TrimmedForm
validateForm form =
    let
        trimmedForm =
            trimFields form
    in
    case List.concatMap (validateField trimmedForm) fieldsToValidate of
        [] ->
            Ok trimmedForm

        problems ->
            Err problems


validateField : TrimmedForm -> ValidatedField -> List Problem
validateField (Trimmed form) field =
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


trimFields : Form -> TrimmedForm
trimFields form =
    Trimmed
        { username = String.trim form.username
        , email = String.trim form.email
        , password = String.trim form.password
        }


invalidEntryToString : List Problem -> ValidatedField -> String
invalidEntryToString problems field =
    getInvalidEntry problems field
        |> List.map problemToString
        |> String.join ""


serverErrorToString : List Problem -> String
serverErrorToString problems =
    getServerError problems
        |> List.map problemToString
        |> String.join ""


getInvalidEntry : List Problem -> ValidatedField -> List Problem
getInvalidEntry problems validatedField =
    List.filter
        (\problem ->
            case problem of
                InvalidEntry field _ ->
                    field == validatedField

                _ ->
                    False
        )
        problems


getServerError : List Problem -> List Problem
getServerError problems =
    List.filter
        (\problem ->
            case problem of
                ServerError _ ->
                    True

                InvalidEntry _ _ ->
                    False
        )
        problems


problemToString : Problem -> String
problemToString problem =
    case problem of
        InvalidEntry _ str ->
            str

        ServerError { message } ->
            message



-- VIEW


view : Model -> Html Msg
view { form, problems, isLoading } =
    div [] [ viewSignupForm form problems isLoading ]


viewFormInvalidEntry : List Problem -> ValidatedField -> Html msg
viewFormInvalidEntry problems field =
    div [ class "h-1" ] [ p [ class "text-sm text-red-500 mt-2" ] [ text <| invalidEntryToString problems field ] ]


viewFormServerError : List Problem -> Html msg
viewFormServerError problems =
    div [ class "h-1" ] [ p [ class "text-sm mt-1 text-red-500" ] [ text <| serverErrorToString problems ] ]


viewSignupForm : Form -> List Problem -> Bool -> Html Msg
viewSignupForm form problems isLoading =
    div [ class "flex flex-col font-light text-black text-start lg:w-96 md:w-96 sm:w-40" ]
        [ header [ class "text-2xl mb-6 font-medium font-serif" ] [ text "Join mitsumori" ]
        , Html.form [ id "signup-form" ]
            [ div [ class "flex flex-col mt-2" ]
                [ label [ class "text-gray-900", for "email" ]
                    [ text "Email address" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", not (String.isEmpty <| invalidEntryToString problems Email) ) ]
                    , id "email"
                    , placeholder "your.email@address.com"
                    , type_ "text"
                    , value form.email
                    , onInput OnEmailChange
                    ]
                    [ text form.email ]
                , viewFormInvalidEntry problems Email
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-900 mt-2", for "username" ]
                    [ text "Username" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", not (String.isEmpty <| invalidEntryToString problems Username) ) ]
                    , id "username"
                    , placeholder "johndoe"
                    , type_ "text"
                    , value form.username
                    , onInput OnUsernameChange
                    ]
                    [ text form.email ]
                , viewFormInvalidEntry problems Username
                ]
            , div [ class "flex flex-col mt-6" ]
                [ label [ class "text-gray-700 mt-2", for "password" ]
                    [ text "Password (8+ chars)" ]
                , input
                    [ class "mt-3 p-2 border border-gray-300 rounded-lg hover:border-gray-500 focus:border-gray-700 focus:outline-0 focus:ring focus:ring-slate-300"
                    , classList [ ( "border-red-500", not (String.isEmpty <| invalidEntryToString problems Password) ) ]
                    , id "password"
                    , placeholder "Choose your password"
                    , type_ "password"
                    , value form.password
                    , onInput OnPasswordChange
                    ]
                    [ text form.password ]
                , viewFormInvalidEntry problems Password
                ]
            , viewFormServerError problems
            ]
        , div [ class "flex mt-9 justify-between items-center" ]
            [ Button.create { label = "Create account", onClick = OnSubmit }
                |> Button.withIsLoading isLoading
                |> Button.view
            , button [ onClick <| NavigateTo Route.Signin, class "ml-2 text-gray-700 underline underline-offset-2 hover:text-black transition ease-in-out hover:-translate-y-0.5 duration-300s" ] [ text "Or sign in" ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Supabase.signUpResponse GotSignupResponse
