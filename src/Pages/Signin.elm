module Pages.Signin exposing (Model, Msg(..), init, subscriptions, update, view)

import Components.Button as Button
import Html exposing (Html, a, div, form, header, input, label, p, text)
import Html.Attributes exposing (class, classList, for, href, id, placeholder, type_, value)
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
    , problems : List Problem
    }


type alias Form =
    { email : String
    , password : String
    }


type Problem
    = InvalidEntry ValidatedField String
    | ServerError Supabase.Error


type SigninResponse
    = UserOk User.User
    | SignupError Supabase.Error
    | PayloadError


init : () -> ( Model, Cmd Msg )
init _ =
    ( { form =
            { email = ""
            , password = ""
            }
      , problems = []
      }
    , Cmd.none
    )


encodeForm : Form -> JE.Value
encodeForm { email, password } =
    JE.object
        [ ( "email", JE.string <| String.trim email )
        , ( "password", JE.string <| String.trim password )
        ]


signInResponseDecoder : JE.Value -> SigninResponse
signInResponseDecoder json =
    JD.decodeValue
        (JD.oneOf
            [ JD.map UserOk User.decoder, JD.map SignupError Supabase.errorDecoder ]
        )
        json
        |> Result.withDefault PayloadError



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
            case validateForm model.form of
                Ok validForm ->
                    ( { model | problems = [] }, Supabase.signIn (encodeForm validForm), Shared.NoUpdate )

                Err problems ->
                    ( { model | problems = problems }, Cmd.none, Shared.NoUpdate )

        GotSigninResponse json ->
            let
                signinResponse =
                    signInResponseDecoder json
            in
            case signinResponse of
                UserOk user ->
                    ( { model | form = emptyForm }, Route.pushUrl shared.key Route.Home, Shared.UpdateUser user )

                SignupError error ->
                    let
                        serverErrors =
                            List.map ServerError [ error ]
                    in
                    ( { model | problems = List.append model.problems serverErrors }, Cmd.none, Shared.NoUpdate )

                PayloadError ->
                    ( model, Cmd.none, Shared.NoUpdate )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none, Shared.NoUpdate )


emptyForm : Form
emptyForm =
    { email = "", password = "" }



-- FORM TYPES/HELPERS


type ValidatedField
    = Email
    | Password


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Email, Password ]


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

            Password ->
                if String.isEmpty form.password then
                    [ "Password can't be blank." ]

                else if String.length form.password < 8 then
                    [ "Password must be at least 8 characters long." ]

                else
                    []


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
view model =
    div [] [ viewSigninForm model.form model.problems ]


viewFormInvalidEntry : List Problem -> ValidatedField -> Html msg
viewFormInvalidEntry problems field =
    div [ class "h-1" ] [ p [ class "text-sm text-red-500 mt-2" ] [ text <| invalidEntryToString problems field ] ]


viewFormServerError : List Problem -> Html msg
viewFormServerError problems =
    div [ class "h-1" ] [ p [ class "text-sm mt-1 text-red-500" ] [ text <| serverErrorToString problems ] ]


viewSigninForm : Form -> List Problem -> Html Msg
viewSigninForm form problems =
    div [ class "flex flex-col font-light text-black text-start lg:w-96 md:w-96 sm:w-40" ]
        [ header [ class "text-2xl mb-6 font-medium font-serif" ] [ text "Welcome back" ]
        , Html.form [ id "signup-form" ]
            [ div [ class "flex flex-col my-2" ]
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
            [ Button.create { label = "Sign in", onClick = OnSubmit } |> Button.view
            , a [ href <| "signup", class "text-gray-700 underline underline-offset-2" ] [ text "Or sign up" ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ Supabase.signInResponse GotSigninResponse ]
