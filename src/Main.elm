module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Home
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
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
            updateUrl url { page = NotFound, key = key, seed = Random.initialSeed flags.seed }

        Err _ ->
            updateUrl url { page = NotFound, key = key, seed = Random.initialSeed 0 }


flagsDecoder : JD.Decoder Flags
flagsDecoder =
    JD.map Flags
        (JD.field "seed" JD.int)



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HomeMsg Home.Msg
    | NoOp


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

        NoOp ->
            ( model, Cmd.none )


toHome : Model -> ( Home.Model, Cmd Home.Msg ) -> ( Model, Cmd Msg )
toHome model ( home, cmds ) =
    ( { model | page = HomePage home }, Cmd.map HomeMsg cmds )


updateUrl : Url.Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Route.fromUrl url of
        Just Route.Home ->
            Home.init model.key
                |> toHome model

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.page of
        HomePage homeModel ->
            { title = "Home"
            , body = [ pageFrame (Home.view homeModel) ]
            }

        NotFound ->
            { title = "NotFound"
            , body = [ viewNotFoundPage ]
            }


pageFrame : Html Msg -> Html Msg
pageFrame children =
    div [ class "flex justify-center h-full w-full" ]
        [ div [ class "flex-col text-center justify-center" ]
            [ div [ class "text-5xl mt-8" ] [ text "mitsumori" ]
            , div [ class "flex flex-col justify-center" ] [ children ]
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



-- Ports.getQuotesResponse RecievedQuotes
