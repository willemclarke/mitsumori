module Main exposing (Session, main)

import Browser
import Browser.Navigation as Nav
import Home
import Html exposing (Html, a, div, p, text)
import Html.Attributes exposing (class, href)
import Json.Decode as JD
import Json.Encode as JE
import Random exposing (Seed)
import Route
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


type alias Session =
    { key : Nav.Key
    , seed : Seed
    }


type Page
    = HomePage Home.Model
    | NotFound


type alias Flags =
    { seed : Int
    }


init : JE.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flagsValue url key =
    let
        decodedFlags =
            JD.decodeValue flagsDecoder flagsValue
    in
    case decodedFlags of
        Ok flags ->
            updateUrl url { page = NotFound, key = key, session = { key = key, seed = Random.initialSeed flags.seed } }

        Err _ ->
            updateUrl url { page = NotFound, key = key, session = { key = key, seed = Random.initialSeed 0 } }


flagsDecoder : JD.Decoder Flags
flagsDecoder =
    JD.map Flags
        (JD.field "seed" JD.int)



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HomeMsg Home.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged _ ->
            ( model, Cmd.none )

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


toHome : Model -> ( Home.Model, Cmd Home.Msg ) -> ( Model, Cmd Msg )
toHome model ( home, cmds ) =
    ( { model | page = HomePage home }, Cmd.map HomeMsg cmds )


updateUrl : Url.Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Route.fromUrl url of
        Just Route.Home ->
            Home.init model.session
                |> toHome model

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.page of
        HomePage homeModel ->
            pageFrame { title = "Home", children = Home.view homeModel |> Html.map HomeMsg }

        NotFound ->
            pageFrame { title = "NotFound", children = viewNotFoundPage }


pageFrame : { title : String, children : Html Msg } -> Browser.Document Msg
pageFrame { title, children } =
    { title = title
    , body =
        [ div [ class "flex justify-center h-full w-full" ]
            [ div [ class "flex-col text-center justify-center" ]
                [ viewNav
                , div [ class "flex flex-col justify-center mt-8" ] [ children ]
                ]
            ]
        ]
    }


viewNav : Html msg
viewNav =
    div [ class "flex mt-8 items-center" ]
        [ p [ class "text-5xl mr-3" ] [ text "mitsumori" ]
        , a [ href "/signup", class "text 3xl mr-2" ] [ text "signup" ]
        , a [ href "/signin", class "text 3xl" ] [ text "signin" ]
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



-- Ports.getQuotesResponse RecievedQuotes
