module Main exposing (Model, main)

-- import Route exposing (Route)

import Actions exposing (Actions(..))
import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, div, p, text)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Json.Decode as JD
import Json.Encode as JE
import Pages.Home as Home
import Pages.Signin as Signin
import Pages.Signup as Signup
import Random
import Router.Route as Route
import Router.Router as Router
import Shared exposing (Shared, SharedUpdate(..), SupabaseFlags)
import Supabase
import Url
import User exposing (User, UserType(..))



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
    { key : Nav.Key
    , url : Url.Url
    , appState : AppState
    }


type AppState
    = Initialising { supabase : SupabaseFlags, seed : Random.Seed }
    | Ready Shared Router.Model
    | FailedToInitialise


type alias Flags =
    { supabase : Shared.SupabaseFlags
    , seed : Int
    }


init : JE.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flagsValue url key =
    case JD.decodeValue flagsDecoder flagsValue of
        Ok flags ->
            ( { key = key, url = url, appState = Initialising { supabase = flags.supabase, seed = Random.initialSeed flags.seed } }, Supabase.session () )

        Err _ ->
            ( { key = key, url = url, appState = FailedToInitialise }, Cmd.none )


flagsDecoder : JD.Decoder Flags
flagsDecoder =
    JD.map2 Flags
        (JD.field "supabase" supabaseFlagsDecoder)
        (JD.field "seed" JD.int)


supabaseFlagsDecoder : JD.Decoder Shared.SupabaseFlags
supabaseFlagsDecoder =
    JD.map2 Shared.SupabaseFlags
        (JD.field "supabaseUrl" JD.string)
        (JD.field "supabaseKey" JD.string)



-- UPDATE


type Msg
    = UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest
    | HandleSessionResponse JE.Value
    | RouterMsg Router.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            updateRouter { model | url = url } (Router.UrlChanged url)

        RouterMsg routerMsg ->
            updateRouter model routerMsg

        HandleSessionResponse json ->
            updateUserSession model json

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key <| Url.toString url )

                Browser.External href ->
                    ( model, Nav.load href )


updateRouter : Model -> Router.Msg -> ( Model, Cmd Msg )
updateRouter model routerMsg =
    case model.appState of
        Ready sharedState routerModel ->
            let
                nextSharedState =
                    Shared.update sharedState sharedStateUpdate

                ( nextRouterModel, routerCmd, sharedStateUpdate ) =
                    Router.update sharedState routerMsg routerModel
            in
            ( { model | appState = Ready nextSharedState nextRouterModel }
            , Cmd.map RouterMsg routerCmd
            )

        _ ->
            let
                _ =
                    Debug.log "We got a router message even though the app is not ready?"
                        routerMsg
            in
            ( model, Cmd.none )


updateUserSession : Model -> JE.Value -> ( Model, Cmd Msg )
updateUserSession model json =
    let
        decoded =
            JD.decodeValue (JD.nullable User.decoder) json
    in
    case decoded of
        Err _ ->
            ( { model | appState = FailedToInitialise }, Cmd.none )

        {- Need to Maybe.map userSession as its possible there was not a session in localstorage.
           If storage was Nothing, map to the Unauthenticated state
        -}
        Ok userSession ->
            let
                user =
                    userSession
                        |> Maybe.map (\usrSession -> usrSession)
                        |> Maybe.withDefault User.unauthenticated
            in
            case model.appState of
                Initialising { supabase, seed } ->
                    let
                        initSharedState =
                            { key = model.key, url = model.url, user = user, supabase = supabase, seed = seed }

                        ( initRouterModel, routerCmd ) =
                            Router.init model.url
                    in
                    ( { model | appState = Ready initSharedState initRouterModel }, Cmd.map RouterMsg routerCmd )

                Ready sharedState routerModel ->
                    ( { model | appState = Ready (Shared.update sharedState <| UpdateUser user) routerModel }, Cmd.none )

                FailedToInitialise ->
                    ( model, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.appState of
        Initialising _ ->
            { title = "Loading"
            , body = [ text "Loading" ]
            }

        Ready sharedState routerModel ->
            Router.view RouterMsg sharedState routerModel

        FailedToInitialise ->
            { title = "Failure"
            , body = [ text "The application failed to initialize. " ]
            }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.appState of
        Initialising _ ->
            Sub.batch [ Supabase.sessionResponse HandleSessionResponse ]

        Ready shared routerModel ->
            Sub.none

        FailedToInitialise ->
            Sub.none



-- let
--     subpageSubs =
--         case model.page of
--             HomePage home ->
--                 Sub.map HomeMsg (Home.subscriptions home)
--             Signup signUp ->
--                 Sub.map SignupMsg (Signup.subscriptions signUp)
--             Signin signIn ->
--                 Sub.map SigninMsg (Signin.subscriptions signIn)
--             _ ->
--                 Sub.none
-- in
-- Sub.batch [ subpageSubs, e ]
