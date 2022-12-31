module Pages.Profile exposing (Model, Msg(..), init, subscriptions, update, view)

import Components.Spinner as Spinner
import Graphql.Http
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Html.Events
import Html.Extra as HE
import RemoteData exposing (RemoteData(..))
import Routing.Route as Route
import Shared exposing (Shared)
import Supabase
import Url


type alias Model =
    { profile : RemoteData (Graphql.Http.Error Supabase.Profiles) Supabase.Profiles
    }


init : Shared -> Url.Url -> ( Model, Cmd Msg )
init shared url =
    let
        x =
            Debug.log "init has been called"
    in
    case userIdFromRoute url of
        Just userId ->
            ( { profile = RemoteData.Loading }, Supabase.getProfile GotProfileResponse userId shared )

        Nothing ->
            ( { profile = RemoteData.NotAsked }, Cmd.none )


userIdFromRoute : Url.Url -> Maybe String
userIdFromRoute url =
    case Route.fromUrl url of
        Just (Route.Profile id) ->
            Just id

        _ ->
            Nothing


type Msg
    = GotProfileResponse (RemoteData (Graphql.Http.Error Supabase.Profiles) Supabase.Profiles)
    | NoOp


update : Shared -> Msg -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
update shared msg model =
    case msg of
        GotProfileResponse resp ->
            ( { model | profile = resp }, Cmd.none, Shared.NoUpdate )

        NoOp ->
            ( model, Cmd.none, Shared.NoUpdate )


view : Shared -> Model -> Html Msg
view shared model =
    div [ class "flex flex-col h-full w-full items-center mt-12" ]
        [ case model.profile of
            RemoteData.Loading ->
                Spinner.spinner

            RemoteData.Success profiles ->
                case List.head profiles.profiles of
                    Just profile ->
                        div [ class "bg-red" ] [ text profile.username ]

                    Nothing ->
                        HE.nothing

            _ ->
                HE.nothing
        ]


subscriptions : Sub Msg
subscriptions =
    Sub.none
