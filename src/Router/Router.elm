module Router.Router exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, div, p, text)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Pages.Home as Home
import Pages.Signin as SignIn
import Pages.Signup as SignUp
import Router.Route as Route exposing (Route)
import Shared exposing (Shared)
import Supabase
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


init : Url.Url -> ( Model, Cmd Msg )
init url =
    let
        ( homeModel, homeCmd ) =
            Home.init ()

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
            updateHome model homeMsg

        SignUpMsg signUpMsg ->
            updateSignUp shared model signUpMsg

        SignInMsg signInMsg ->
            updateSignIn model signInMsg

        SignOut ->
            ( model, Cmd.batch [ Supabase.signOut (), Nav.reload ], Shared.NoUpdate )



-- remember when I want to setUser from Signup/Signin i will have to come back here and add Shared.SetUser


updateHome : Model -> Home.Msg -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateHome model homeMsg =
    let
        ( nextHomeModel, homeCmd ) =
            Home.update homeMsg model.homeModel
    in
    ( { model | homeModel = nextHomeModel }, Cmd.map HomeMsg homeCmd, Shared.NoUpdate )


updateSignUp : Shared -> Model -> SignUp.Msg -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateSignUp shared model signUpMsg =
    let
        ( nextSignUpModel, signUpCmd, sharedUpdate ) =
            SignUp.update shared signUpMsg model.signUpModel
    in
    ( { model | signUpModel = nextSignUpModel }, Cmd.map SignUpMsg signUpCmd, sharedUpdate )


updateSignIn : Model -> SignIn.Msg -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateSignIn model signInMsg =
    let
        ( nextSignInModel, signInCmd ) =
            SignIn.update signInMsg model.signInModel
    in
    ( { model | signInModel = nextSignInModel }, Cmd.map SignInMsg signInCmd, Shared.NoUpdate )


view : (Msg -> msg) -> Shared -> Model -> Browser.Document msg
view msgMapper shared model =
    let
        title =
            Route.toTitleString (Maybe.withDefault Route.NotFound model.route)

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



-- this needs to be based off of the route


pageView : Shared -> Model -> Html Msg
pageView shared model =
    case model.route of
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
viewNav shared =
    div [ class "flex mt-4 mx-6 justify-between items-end font-serif" ]
        [ a [ href <| Route.toString Route.Home, class "text-3xl" ] [ text "mitsumori" ]
        , div [ class "flex" ]
            [ case User.userType shared.user of
                User.Authenticated _ ->
                    div [ onClick SignOut ] [ p [ class "text-lg cursor-pointer" ] [ text "logout" ], p [ class "text-normal" ] [ text <| "Logged in as " ++ User.username shared.user ] ]

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
