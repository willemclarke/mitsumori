module Routing.Router exposing (Model, Msg(..), init, subscriptions, update, view)

import Browser
import Browser.Navigation
import Components.Button as Button
import Components.Dropdown as Dropdown
import Components.Toast as Toast
import Heroicons.Outline as HeroIcons
import Html exposing (Html, a, div, text)
import Html.Attributes exposing (class, href)
import Json.Decode as JD
import Json.Encode as JE
import Pages.Home as Home
import Pages.Profile as Profile
import Pages.Signin as SignIn
import Pages.Signup as SignUp
import Process
import Routing.Route as Route exposing (Route)
import Shared exposing (Shared)
import Supabase
import Svg.Attributes as SvgAttr
import Task
import Time
import Url
import User exposing (UserType(..))
import Uuid


type alias Model =
    { homeModel : Home.Model
    , profileModel : Profile.Model
    , signUpModel : SignUp.Model
    , signInModel : SignIn.Model
    , route : Maybe Route
    , isDropdownOpen : Bool
    }


type SignOutResponse
    = SignoutSuccess String
    | SignoutError Supabase.AuthError
    | PayloadError


type Msg
    = UrlChanged Url.Url
    | NavigateTo Route
    | HomeMsg Home.Msg
    | ProfileMsg Profile.Msg
    | SignUpMsg SignUp.Msg
    | SignInMsg SignIn.Msg
    | SignOut
    | GotSignOutResponse JE.Value
    | CloseToast Uuid.Uuid
    | OnDropdownClicked
    | OnDropdownBlurred
    | Tick Time.Posix
    | NoOp


init : Shared -> Url.Url -> ( Model, Cmd Msg )
init shared url =
    let
        x =
            Debug.log "Router.init called" url

        ( homeModel, homeCmd ) =
            Home.init shared

        ( profileModel, _ ) =
            Profile.init shared

        ( signUpModel, _ ) =
            SignUp.init ()

        ( signInModel, signinCmd ) =
            SignIn.init ()

        cmd =
            if User.isAuthenticated shared.user then
                Cmd.map HomeMsg homeCmd

            else
                Cmd.map SignInMsg signinCmd
    in
    ( { homeModel = homeModel
      , profileModel = profileModel
      , signUpModel = signUpModel
      , signInModel = signInModel
      , route = Route.fromUrl url
      , isDropdownOpen = False
      }
    , cmd
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
                cmd =
                    case Route.fromUrl url of
                        Just (Route.Home _) ->
                            Browser.Navigation.reload

                        _ ->
                            Cmd.none
            in
            ( { model | route = Route.fromUrl url }
            , Cmd.none
            , Shared.NoUpdate
            )

        NavigateTo route ->
            ( model, Route.replaceUrl shared.key route, Shared.NoUpdate )

        HomeMsg homeMsg ->
            updateHome shared model homeMsg

        ProfileMsg profileMsg ->
            updateProfile shared model profileMsg

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
                    ( model, Route.replaceUrl shared.key Route.Signin, Shared.UpdateUser User.unauthenticated )

                {- TODO, proper error handling, need some view to show to users -}
                SignoutError _ ->
                    ( model, Cmd.none, Shared.NoUpdate )

                PayloadError ->
                    ( model, Cmd.none, Shared.NoUpdate )

        CloseToast id ->
            ( model, Cmd.none, Shared.CloseToast id )

        OnDropdownClicked ->
            ( { model | isDropdownOpen = not model.isDropdownOpen }, Cmd.none, Shared.NoUpdate )

        OnDropdownBlurred ->
            ( { model | isDropdownOpen = False }, Cmd.none, Shared.NoUpdate )

        Tick _ ->
            let
                closeToastCmds =
                    shared.toasts
                        |> List.map (\( _, uuid ) -> after 5000 (CloseToast uuid))
                        |> Cmd.batch
            in
            ( model, closeToastCmds, Shared.NoUpdate )

        NoOp ->
            ( model, Cmd.none, Shared.NoUpdate )


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


updateProfile : Shared -> Model -> Profile.Msg -> ( Model, Cmd Msg, Shared.SharedUpdate )
updateProfile shared model profileMsg =
    let
        ( nextProfileModel, profileCmd, sharedUpdate ) =
            Profile.update shared profileMsg model.profileModel
    in
    ( { model | profileModel = nextProfileModel }, Cmd.map ProfileMsg profileCmd, sharedUpdate )


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
                [ viewNav { isDropdownOpen = model.isDropdownOpen } shared
                , div [ class "flex flex-col items-center justify-center h-full w-full" ]
                    [ pageView shared model
                    , Toast.region toasts
                    ]
                ]
    in
    { title = title ++ " - Mitsumori"
    , body = [ content |> Html.map msgMapper ]
    }


pageView : Shared -> Model -> Html Msg
pageView shared model =
    case Route.checkNav shared.user model.route of
        Just (Route.Home _) ->
            Home.view shared model.homeModel
                |> Html.map HomeMsg

        Just (Route.Profile _) ->
            Profile.view shared model.profileModel
                |> Html.map ProfileMsg

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


viewNav : { isDropdownOpen : Bool } -> Shared -> Html Msg
viewNav { isDropdownOpen } shared =
    let
        href_ =
            if User.isAuthenticated shared.user then
                Route.toString (Route.Home Route.emptyFilter)

            else
                Route.toString Route.Signup
    in
    div [ class "flex mt-4 mx-6 justify-between items-end font-serif" ]
        [ a [ href href_, class "text-3xl transition ease-in-out hover:-translate-y-0.5 duration-300" ] [ text "mitsumori" ]
        , div [ class "flex" ]
            [ if User.isAuthenticated shared.user then
                Dropdown.create
                    { user = User.user shared.user
                    , onClick = OnDropdownClicked
                    , onBlur = OnDropdownBlurred
                    , isOpen = isDropdownOpen
                    , options =
                        [ { label = "Profile"
                          , onClick = NavigateTo (Route.Profile (User.id shared.user))
                          , icon = Just (HeroIcons.userCircle [ SvgAttr.class "w-5 h-5" ])
                          }
                        , { label = "Signout"
                          , onClick = SignOut
                          , icon = Just (HeroIcons.logout [ SvgAttr.class "w-5 h-5" ])
                          }
                        ]
                    }
                    |> Dropdown.view

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
                Just (Route.Home _) ->
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
