module Router.Router exposing (Model, Msg(..), init, subscriptions, update, view)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, div, p, text)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Pages.Home as Home
import Pages.Signin as SignIn
import Pages.Signup as SignUp
import Process
import Router.Route as Route exposing (Route)
import Shared exposing (Shared)
import Supabase
import Task
import Url
import User exposing (UserType(..))


type alias Model =
    { homeModel : Home.Model
    , signUpModel : SignUp.Model
    , signInModel : SignIn.Model
    , route : Maybe Route
    }


type Msg
    = UrlChanged Url.Url
    | NavigateTo Route
    | HomeMsg Home.Msg
    | SignUpMsg SignUp.Msg
    | SignInMsg SignIn.Msg
    | SignOut
    | Refresh


init : Shared -> Url.Url -> ( Model, Cmd Msg )
init shared url =
    let
        ( homeModel, homeCmd ) =
            Home.init shared

        ( signUpModel, _ ) =
            SignUp.init ()

        ( signInModel, _ ) =
            SignIn.init ()
    in
    ( { homeModel = homeModel
      , signUpModel = signUpModel
      , signInModel = signInModel
      , route = Route.fromUrl url
      }
    , Cmd.map HomeMsg homeCmd
    )


update : Shared -> Msg -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
update shared msg model =
    case msg of
        UrlChanged url ->
            ( { model | route = Route.fromUrl url }, Cmd.none, Shared.NoUpdate )

        NavigateTo route ->
            ( model, Nav.pushUrl shared.key <| Route.toString route, Shared.NoUpdate )

        HomeMsg homeMsg ->
            updateHome shared model homeMsg

        SignUpMsg signUpMsg ->
            updateSignUp shared model signUpMsg

        SignInMsg signInMsg ->
            updateSignIn shared model signInMsg

        SignOut ->
            ( model, Cmd.batch [ Supabase.signOut (), after 600 Refresh ], Shared.NoUpdate )

        Refresh ->
            ( model, Cmd.batch [ Nav.reload ], Shared.NoUpdate )


after : Float -> msg -> Cmd msg
after time msg =
    Task.perform (always msg) <| Process.sleep time


updateHome : Shared -> Model -> Home.Msg -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateHome shared model homeMsg =
    let
        ( nextHomeModel, homeCmd, sharedUpdate ) =
            Home.update shared homeMsg model.homeModel
    in
    ( { model | homeModel = nextHomeModel }, Cmd.map HomeMsg homeCmd, sharedUpdate )


updateSignUp : Shared -> Model -> SignUp.Msg -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateSignUp shared model signUpMsg =
    let
        ( nextSignUpModel, signUpCmd, sharedUpdate ) =
            SignUp.update shared signUpMsg model.signUpModel
    in
    ( { model | signUpModel = nextSignUpModel }, Cmd.map SignUpMsg signUpCmd, sharedUpdate )


updateSignIn : Shared -> Model -> SignIn.Msg -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateSignIn shared model signInMsg =
    let
        ( nextSignInModel, signInCmd, sharedUpdate ) =
            SignIn.update shared signInMsg model.signInModel
    in
    ( { model | signInModel = nextSignInModel }, Cmd.map SignInMsg signInCmd, sharedUpdate )


view : (Msg -> msg) -> Shared -> Model -> Browser.Document msg
view msgMapper shared model =
    let
        title =
            Route.toTitleString (Maybe.withDefault Route.NotFound model.route)

        content =
            div [ class "flex flex-col h-full w-full" ]
                [ viewNav shared
                , div [ class "flex flex-col items-center justify-center h-full w-full" ]
                    [ pageView shared model ]
                ]
    in
    { title = title ++ " - Mitsumori"
    , body = [ content |> Html.map msgMapper ]
    }


pageView : Shared -> Model -> Html Msg
pageView { user } model =
    case Route.checkNav user model.route of
        Just Route.Home ->
            Home.view model.homeModel
                |> Html.map HomeMsg

        Just Route.Signup ->
            SignUp.view model.signUpModel
                |> Html.map SignUpMsg

        Just Route.Signin ->
            SignIn.view model.signInModel
                |> Html.map SignInMsg

        Just Route.NotFound ->
            viewNotFoundPage

        Nothing ->
            viewNotFoundPage


viewNav : Shared -> Html Msg
viewNav { user } =
    let
        href_ =
            if User.isAuthenticated user then
                Route.toString Route.Home

            else
                Route.toString Route.Signup
    in
    div [ class "flex mt-4 mx-6 justify-between items-end font-serif" ]
        [ a [ href href_, class "text-3xl" ] [ text "mitsumori" ]
        , div [ class "flex" ]
            [ case User.userType user of
                User.Authenticated _ ->
                    p [ onClick SignOut, class "text-lg cursor-pointer" ] [ text "signout" ]

                User.Unauthenticated ->
                    div []
                        [ a [ href <| Route.toString Route.Signup, class "text-lg mr-4" ] [ text "signup" ]
                        , a [ href <| Route.toString Route.Signin, class "text-lg mr-4" ] [ text "signin" ]
                        ]
            ]
        ]


viewNotFoundPage : Html msg
viewNotFoundPage =
    div [ class "flex justify-center h-full w-full mt-52 font-serif" ]
        [ div [ class "flex-col text-center justify-center" ]
            [ div [ class "text-3xl mt-8" ] [ text "Page not found :(" ]
            ]
        ]


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions msgMapper model =
    case model.route of
        Just Route.Home ->
            Sub.map HomeMsg (Home.subscriptions model.homeModel) |> Sub.map msgMapper

        Just Route.Signup ->
            Sub.map SignUpMsg (SignUp.subscriptions model.signUpModel) |> Sub.map msgMapper

        Just Route.Signin ->
            Sub.map SignInMsg (SignIn.subscriptions model.signInModel) |> Sub.map msgMapper

        _ ->
            Sub.none
