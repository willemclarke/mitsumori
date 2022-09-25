module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, div, p, text)
import Html.Attributes exposing (class, href)
import Json.Decode as JD
import Json.Encode as JE
import Pages.Home as Home
import Pages.Signin as Signin
import Pages.Signup as Signup
import Random exposing (Seed)
import Route
import Session exposing (Session)
import Url



-- MAIN


main : Program JE.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { page : Page
    , key : Nav.Key
    , session : Session
    }


type Page
    = HomePage Home.Model
    | Signup Signup.Model
    | Signin Signin.Model
    | NotFound


type alias Flags =
    { supabaseUrl : String
    , supabaseKey : String
    , seed : Int
    }


init : JE.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flagsValue url key =
    let
        decodedFlags =
            JD.decodeValue flagsDecoder flagsValue
    in
    case decodedFlags of
        Ok flags ->
            updateUrl url
                { page = NotFound
                , key = key
                , session =
                    { key = key
                    , seed = Random.initialSeed flags.seed
                    , supabaseUrl = flags.supabaseUrl
                    , supabaseKey = flags.supabaseKey
                    }
                }

        Err _ ->
            updateUrl url
                { page = NotFound
                , key = key
                , session =
                    { key = key
                    , seed = Random.initialSeed 0
                    , supabaseUrl = ""
                    , supabaseKey = ""
                    }
                }


flagsDecoder : JD.Decoder Flags
flagsDecoder =
    JD.map3 Flags
        (JD.field "supabaseUrl" JD.string)
        (JD.field "supabaseKey" JD.string)
        (JD.field "seed" JD.int)



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HomeMsg Home.Msg
    | SignupMsg Signup.Msg
    | SigninMsg Signin.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            updateUrl url model

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key <| Url.toString url )

                Browser.External href ->
                    ( model, Nav.load href )

        HomeMsg homeMsg ->
            case model.page of
                HomePage homeModel ->
                    toHome model (Home.update homeMsg homeModel)

                _ ->
                    ( model, Cmd.none )

        SignupMsg signupMsg ->
            case model.page of
                Signup signupModel ->
                    toSignup model (Signup.update signupMsg signupModel)

                _ ->
                    ( model, Cmd.none )

        SigninMsg loginMsg ->
            case model.page of
                Signin loginModel ->
                    toSignin model (Signin.update loginMsg loginModel)

                _ ->
                    ( model, Cmd.none )



-- TODO : toSignup, toLogin


toHome : Model -> ( Home.Model, Cmd Home.Msg ) -> ( Model, Cmd Msg )
toHome model ( homeModel, cmds ) =
    ( { model | page = HomePage homeModel }, Cmd.map HomeMsg cmds )


toSignup : Model -> ( Signup.Model, Cmd Signup.Msg ) -> ( Model, Cmd Msg )
toSignup model ( signupModel, cmds ) =
    ( { model | page = Signup signupModel }, Cmd.map SignupMsg cmds )


toSignin : Model -> ( Signin.Model, Cmd Signin.Msg ) -> ( Model, Cmd Msg )
toSignin model ( loginModel, cmds ) =
    ( { model | page = Signin loginModel }, Cmd.map SigninMsg cmds )


updateUrl : Url.Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Route.fromUrl url of
        Just Route.Home ->
            Home.init model.session
                |> toHome model

        Just Route.Signup ->
            Signup.init model.session
                |> toSignup model

        Just Route.Signin ->
            Signin.init ()
                |> toSignin model

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        viewPage toMsg config =
            pageFrame
                { title = config.title
                , content = Html.map toMsg config.content
                }
    in
    case model.page of
        HomePage homeModel ->
            viewPage HomeMsg (Home.view homeModel)

        Signup signupModel ->
            viewPage SignupMsg (Signup.view signupModel)

        Signin signinModel ->
            viewPage SigninMsg (Signin.view signinModel)

        NotFound ->
            pageFrame { title = "NotFound", content = viewNotFoundPage }


pageFrame : { title : String, content : Html Msg } -> Browser.Document Msg
pageFrame { title, content } =
    { title = title ++ " - Mitsumori"
    , body =
        [ div [ class "flex flex-col h-full w-full" ]
            [ viewNav
            , div [ class "flex flex-col items-center h-full" ]
                [ div [ class "flex flex-col justify-center mt-8 ml-4" ] [ content ]
                ]
            ]
        ]
    }


viewNav : Html msg
viewNav =
    div [ class "flex mt-4 mx-6 justify-between items-end font-serif" ]
        [ a [ href <| Route.toString Route.Home, class "text-3xl" ] [ text "mitsumori" ]
        , div [ class "flex" ]
            [ a [ href <| Route.toString Route.Signup, class "text-lg mr-4" ] [ text "signup" ]
            , a [ href <| Route.toString Route.Signin, class "text-lg mr-4" ] [ text "signin" ]
            , p [ class "text-lg" ] [ text "logout" ]
            ]
        ]


viewNotFoundPage : Html msg
viewNotFoundPage =
    div [ class "flex justify-center h-full w-full" ]
        [ div [ class "flex-col text-center justify-center" ]
            [ div [ class "text-5xl mt-8" ] [ text "Page not found :(" ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
