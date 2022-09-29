module Router.Router exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, div, p, text)
import Html.Attributes exposing (class, href)
import Pages.Home as Home
import Pages.Signin as SignIn
import Pages.Signup as SignUp
import Router.Route as Route exposing (Route)
import Shared exposing (Shared)
import Url
import User exposing (UserType(..))


type alias Model =
    { page : Page
    , route : Route
    }


type Page
    = HomePage Home.Model
    | SignUp SignUp.Model
    | SignIn SignIn.Model
    | NotFound


type Msg
    = UrlChanged Url.Url
    | NavigateTo Route
    | HomeMsg Home.Msg
    | SignUpMsg SignUp.Msg
    | SignInMsg SignIn.Msg


init : Url.Url -> ( Model, Cmd Msg )
init url =
    let
        ( homeModel, homeCmd ) =
            Home.init ()

        ( signUpModel, signUpMsg ) =
            SignUp.init ()

        ( signInModel, signInMsg ) =
            SignIn.init ()
    in
    ( { page = NotFound
      , route = Route.fromUrl url |> Maybe.withDefault Route.Signin
      }
    , Cmd.map HomeMsg homeCmd
    )


update : Shared -> Msg -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
update shared msg model =
    case msg of
        UrlChanged url ->
            ( { model | route = Route.fromUrl url |> Maybe.withDefault Route.Signin }, Cmd.none, Shared.NoUpdate )

        NavigateTo route ->
            ( model, Nav.pushUrl shared.key <| Route.toString route, Shared.NoUpdate )

        HomeMsg homeMsg ->
            case model.page of
                HomePage homeModel ->
                    updateHome model (Home.update homeMsg homeModel)

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

        SignUpMsg signUpMsg ->
            case model.page of
                SignUp signUpModel ->
                    updateSignUp model (SignUp.update signUpMsg signUpModel)

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

        SignInMsg signInMsg ->
            case model.page of
                SignIn signInModel ->
                    updateSignIn model (SignIn.update signInMsg signInModel)

                _ ->
                    ( model, Cmd.none, Shared.NoUpdate )



-- remember when I want to setUser from Signup/Signin i will have to come back here and add Shared.SetUser


updateHome : Model -> ( Home.Model, Cmd Home.Msg ) -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateHome model ( homeModel, homeCmd ) =
    ( { model | page = HomePage homeModel }, Cmd.map HomeMsg homeCmd, Shared.NoUpdate )


updateSignUp : Model -> ( SignUp.Model, Cmd SignUp.Msg ) -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateSignUp model ( signUpModel, signUpCmd ) =
    ( { model | page = SignUp signUpModel }, Cmd.map SignUpMsg signUpCmd, Shared.NoUpdate )


updateSignIn : Model -> ( SignIn.Model, Cmd SignIn.Msg ) -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateSignIn model ( signInModel, signInCmd ) =
    ( { model | page = SignIn signInModel }, Cmd.map SignInMsg signInCmd, Shared.NoUpdate )


view : (Msg -> msg) -> Shared -> Model -> Browser.Document msg
view msgMapper shared model =
    let
        title =
            Route.toString model.route

        content =
            div [ class "flex flex-col h-full w-full" ]
                [ viewNav shared
                , div [ class "flex flex-col items-center h-full" ]
                    [ div [ class "flex flex-col justify-center mt-8 ml-4" ] [ pageView shared model ]
                    ]
                ]
    in
    { title = title ++ " - Mitsumori"
    , body = [ content |> Html.map msgMapper ]
    }


pageView : Shared -> Model -> Html Msg
pageView shared model =
    case model.page of
        HomePage homeModel ->
            Home.view homeModel
                |> Html.map HomeMsg

        SignUp signUpModel ->
            SignUp.view signUpModel
                |> Html.map SignUpMsg

        SignIn signInModel ->
            SignIn.view signInModel
                |> Html.map SignInMsg

        NotFound ->
            viewNotFoundPage


viewNav : Shared -> Html Msg
viewNav session =
    div [ class "flex mt-4 mx-6 justify-between items-end font-serif" ]
        [ a [ href <| Route.toString Route.Home, class "text-3xl" ] [ text "mitsumori" ]
        , div [ class "flex" ]
            [ case User.userType session.user of
                User.Authenticated _ ->
                    div [] [ p [ class "text-lg cursor-pointer" ] [ text "logout" ], p [ class "text-normal" ] [ text <| "Logged in as " ++ User.username session.user ] ]

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
