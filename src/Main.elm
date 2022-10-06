module Main exposing (Model, main)

import Browser
import Browser.Navigation as Nav
import Components.Spinner as Spinner
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, href)
import Json.Decode as JD
import Json.Encode as JE
import Random
import Router.Router as Router
import Shared exposing (Shared, SharedUpdate(..))
import Supabase
import Url
import User exposing (UserType(..))



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
    = Initialising Flags
    | Ready Shared Router.Model
    | FailedToInitialise


type alias Flags =
    { supabase : Shared.SupabaseFlags
    , seed : Int
    }


init : JD.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flagsValue url key =
    case JD.decodeValue flagsDecoder flagsValue of
        Ok flags ->
            ( { key = key
              , url = url
              , appState =
                    Initialising
                        { supabase = flags.supabase, seed = flags.seed }
              }
            , Supabase.session ()
            )

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



{- This function serves as the foundation to transition from the `Initialising` state
   to the `Ready` state. On init we call to check if the users session is in localstorage.
    If we successfully get back a session we:
        - initialise the whole thing
        - OR update the currently running (`Ready`) app
-}


updateUserSession : Model -> JE.Value -> ( Model, Cmd Msg )
updateUserSession model json =
    let
        decoded =
            JD.decodeValue (JD.nullable User.decoder) json
    in
    case decoded of
        Err _ ->
            ( { model | appState = FailedToInitialise }, Cmd.none )

        Ok userSession ->
            let
                user =
                    Maybe.withDefault User.unauthenticated userSession
            in
            case model.appState of
                Initialising flags ->
                    let
                        initSharedState =
                            { key = model.key, url = model.url, user = user, supabase = flags.supabase, seed = Random.initialSeed flags.seed }

                        ( initRouterModel, routerCmd ) =
                            Router.init initSharedState model.url
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
            , body = [ viewPageLoading ]
            }

        Ready sharedState routerModel ->
            Router.view RouterMsg sharedState routerModel

        FailedToInitialise ->
            { title = "Failure"
            , body = [ text "The application failed to initialize. " ]
            }


viewPageLoading : Html msg
viewPageLoading =
    div [ class "flex flex-col h-full w-full justify-center items-center" ]
        [ Spinner.spinner ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        commonSubs =
            Supabase.sessionResponse HandleSessionResponse
    in
    case model.appState of
        Initialising _ ->
            Sub.batch [ commonSubs ]

        Ready _ routerModel ->
            Sub.batch [ commonSubs, Router.subscriptions RouterMsg routerModel ]

        FailedToInitialise ->
            Sub.none
