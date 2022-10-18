module Router.Router exposing (Model, Msg(..), init, subscriptions, update, view)

import Browser
import Browser.Navigation
import Components.Button as Button
import Components.Toast as Toast
import Html exposing (Html, a, div, text)
import Html.Attributes exposing (class, href)
import Json.Decode as JD
import Json.Encode as JE
import Pages.Home as Home
import Pages.Signin as SignIn
import Pages.Signup as SignUp
import Process
import Router.Route as Route exposing (Route)
import Shared exposing (Shared)
import Supabase
import Task
import Time
import Url
import User exposing (UserType(..))
import Uuid


type alias Model =
    { homeModel : Home.Model
    , signUpModel : SignUp.Model
    , signInModel : SignIn.Model
    , route : Maybe Route
    }


type SignOutResponse
    = SignoutSuccess String
    | SignoutError Supabase.AuthError
    | PayloadError


type Msg
    = UrlChanged Url.Url
    | NavigateTo Route
    | HomeMsg Home.Msg
    | SignUpMsg SignUp.Msg
    | SignInMsg SignIn.Msg
    | SignOut
    | GotSignOutResponse JE.Value
    | CloseToast Uuid.Uuid
    | Tick Time.Posix


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


signOutResponseDecoder : JE.Value -> SignOutResponse
signOutResponseDecoder json =
    JD.decodeValue
        (JD.oneOf
            [ JD.map SignoutSuccess JD.string, JD.map SignoutError Supabase.authErrorDecoder ]
        )
        json
        |> Result.withDefault PayloadError


update : Shared -> Msg -> Model -> ( Model, Cmd Msg, Shared.SharedUpdate )
update shared msg model =
    case msg of
        UrlChanged url ->
            let
                route =
                    Route.fromUrl url

                cmd =
                    case route of
                        Just Route.Home ->
                            Browser.Navigation.reload

                        _ ->
                            Cmd.none
            in
            ( { model | route = Route.fromUrl url }, cmd, Shared.NoUpdate )

        NavigateTo route ->
            ( model, Route.pushUrl shared.key route, Shared.NoUpdate )

        HomeMsg homeMsg ->
            updateHome shared model homeMsg

        SignUpMsg signUpMsg ->
            updateSignUp shared model signUpMsg

        SignInMsg signInMsg ->
            updateSignIn shared model signInMsg

        SignOut ->
            ( model, Supabase.signOut (), Shared.NoUpdate )

        GotSignOutResponse json ->
            let
                signOutResponse =
                    signOutResponseDecoder json
            in
            case signOutResponse of
                SignoutSuccess _ ->
                    ( model, Route.pushUrl shared.key Route.Signin, Shared.UpdateUser <| User.unauthenticated )

                {- TODO, proper error handling, need some view to show to users -}
                SignoutError _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

                PayloadError ->
                    ( model, Cmd.none, Shared.NoUpdate )

        CloseToast id ->
            ( model, Cmd.none, Shared.CloseToast id )

        Tick _ ->
            let
                closeToastCmds =
                    shared.toasts
                        |> List.map (\( _, uuid ) -> after 5000 (CloseToast uuid))
                        |> Cmd.batch
            in
            ( model, closeToastCmds, Shared.NoUpdate )


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

        toasts =
            shared.toasts
                |> List.map
                    (\( toastType, id ) -> Toast.view toastType (CloseToast id))

        content =
            div [ class "flex flex-col h-full w-full" ]
                [ viewNav shared
                , div [ class "flex flex-col items-center justify-center h-full w-full" ]
                    [ pageView shared model, Toast.region toasts ]
                ]
    in
    { title = title ++ " - Mitsumori"
    , body = [ content |> Html.map msgMapper ]
    }


pageView : Shared -> Model -> Html Msg
pageView ({ user } as shared) model =
    case Route.checkNav user model.route of
        Just Route.Home ->
            Home.view shared model.homeModel
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
        [ a [ href href_, class "text-3xl transition ease-in-out hover:-translate-y-0.5 duration-300" ] [ text "mitsumori" ]
        , div [ class "flex" ]
            [ if User.isAuthenticated user then
                div [ class "font-sans" ]
                    [ Button.create { label = "Sign out", onClick = SignOut }
                        |> Button.view
                    ]

              else
                div [ class "font-sans space-x-2" ]
                    [ Button.create { label = "Sign in", onClick = NavigateTo Route.Signin }
                        |> Button.withWhiteAppearance
                        |> Button.view
                    , Button.create { label = "Sign up", onClick = NavigateTo Route.Signup }
                        |> Button.view
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
    let
        pageSubs =
            case model.route of
                Just Route.Home ->
                    Sub.map HomeMsg (Home.subscriptions model.homeModel)

                Just Route.Signup ->
                    Sub.map SignUpMsg (SignUp.subscriptions model.signUpModel)

                Just Route.Signin ->
                    Sub.map SignInMsg (SignIn.subscriptions model.signInModel)

                _ ->
                    Sub.none

        closeToastSub =
            Time.every 2000 Tick

        subs =
            List.map (Sub.map msgMapper) [ Supabase.signOutResponse GotSignOutResponse, pageSubs, closeToastSub ]
    in
    Sub.batch subs
