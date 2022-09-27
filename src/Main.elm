module Main exposing (Model, main)

import Actions exposing (Actions(..))
import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, div, p, text)
import Html.Attributes exposing (class, href)
import Json.Decode as JD
import Json.Encode as JE
import Pages.Home as Home
import Pages.Signin as Signin
import Pages.Signup as Signup
import Random
import Route
import Session exposing (Session)
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
    { page : Page
    , key : Nav.Key
    , url : Url.Url
    , session : Session
    }


type Page
    = HomePage Home.Model
    | Signup Signup.Model
    | Signin Signin.Model
    | NotFound


type alias Flags =
    { supabase : Session.SupabaseFlags
    , seed : Int
    }



{-
   TODO: need to handle when GotSessionResponse comes back as null (Model as maybe in decoder) - aka not authed (preferrably navigate to Login page)
   TODO: same as above except for GotSignupResponse in Signup.elm - when errors - I need to reflect that in the form
       - Add some form validation to Signup / Login
   TODO: Add implementation to logout
   TODO: cleanup Actions type & the way I currently handle actions, try to extract the foldl function
-}


init : JE.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flagsValue url key =
    let
        decodedFlags =
            JD.decodeValue flagsDecoder flagsValue
    in
    case decodedFlags of
        Ok flags ->
            ( { page = NotFound
              , url = url
              , key = key
              , session =
                    { key = key
                    , user = User.unauthenticated
                    , seed = Random.initialSeed flags.seed
                    , supabase = flags.supabase
                    }
              }
            , Supabase.session ()
            )

        Err _ ->
            ( { page = NotFound
              , url = url
              , key = key
              , session =
                    { key = key
                    , user = User.unauthenticated
                    , seed = Random.initialSeed 0
                    , supabase = { supabaseUrl = "", supabaseKey = "" }
                    }
              }
            , Cmd.none
            )


flagsDecoder : JD.Decoder Flags
flagsDecoder =
    JD.map2 Flags
        (JD.field "supabase" supabaseFlagsDecoder)
        (JD.field "seed" JD.int)


supabaseFlagsDecoder : JD.Decoder Session.SupabaseFlags
supabaseFlagsDecoder =
    JD.map2 Session.SupabaseFlags
        (JD.field "supabaseUrl" JD.string)
        (JD.field "supabaseKey" JD.string)



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HomeMsg Home.Msg
    | SignupMsg Signup.Msg
    | SigninMsg Signin.Msg
    | GotSessionResponse JE.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session =
            model.session
    in
    case msg of
        UrlChanged url ->
            updateUrl url model

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key <| Url.toString url )

                Browser.External href ->
                    ( model, Nav.load href )

        GotSessionResponse json ->
            let
                decoded =
                    JD.decodeValue User.decoder json
            in
            case decoded of
                Ok user ->
                    let
                        newModel =
                            { model | session = setSession user session }
                    in
                    updateUrl model.url newModel

                Err _ ->
                    updateUrl model.url model

        HomeMsg homeMsg ->
            case model.page of
                HomePage homeModel ->
                    toHome model (Home.update homeMsg homeModel)

                _ ->
                    ( model, Cmd.none )

        SignupMsg signupMsg ->
            case model.page of
                Signup signupModel ->
                    let
                        ( signUpModel, signUpCmds_, actions ) =
                            Signup.update signupMsg signupModel

                        newModel =
                            List.foldl
                                (\action _ ->
                                    case action of
                                        Actions.SetSession session_ ->
                                            { model | session = session_ }
                                )
                                model
                                actions
                    in
                    toSignup newModel ( signUpModel, signUpCmds_ )

                _ ->
                    ( model, Cmd.none )

        SigninMsg loginMsg ->
            case model.page of
                Signin loginModel ->
                    toSignin model (Signin.update loginMsg loginModel)

                _ ->
                    ( model, Cmd.none )


setSession : User -> Session -> Session
setSession user session =
    { session | user = user }


toHome : Model -> ( Home.Model, Cmd Home.Msg ) -> ( Model, Cmd Msg )
toHome model ( homeModel, cmds ) =
    ( { model | page = HomePage homeModel }, Cmd.map HomeMsg cmds )


toSignup : Model -> ( Signup.Model, Cmd Signup.Msg ) -> ( Model, Cmd Msg )
toSignup model ( signupModel, cmds ) =
    ( { model | page = Signup signupModel }, Cmd.map SignupMsg cmds )


toSignin : Model -> ( Signin.Model, Cmd Signin.Msg ) -> ( Model, Cmd Msg )
toSignin model ( loginModel, cmds ) =
    ( { model | page = Signin loginModel }, Cmd.map SigninMsg cmds )


updateUrl : Url.Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Route.fromUrl url of
        Just Route.Home ->
            Home.init model.session
                |> toHome model

        Just Route.Signup ->
            Signup.init model.session
                |> toSignup model

        Just Route.Signin ->
            Signin.init ()
                |> toSignin model

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        viewPage toMsg config =
            pageFrame model.session
                { title = config.title
                , content = Html.map toMsg config.content
                }
    in
    case model.page of
        HomePage homeModel ->
            viewPage HomeMsg (Home.view homeModel)

        Signup signupModel ->
            viewPage SignupMsg (Signup.view signupModel)

        Signin signinModel ->
            viewPage SigninMsg (Signin.view signinModel)

        NotFound ->
            pageFrame model.session { title = "NotFound", content = viewNotFoundPage }


pageFrame : Session -> { title : String, content : Html Msg } -> Browser.Document Msg
pageFrame session { title, content } =
    { title = title ++ " - Mitsumori"
    , body =
        [ div [ class "flex flex-col h-full w-full" ]
            [ viewNav session
            , div [ class "flex flex-col items-center h-full" ]
                [ div [ class "flex flex-col justify-center mt-8 ml-4" ] [ content ]
                ]
            ]
        ]
    }


viewNav : Session -> Html msg
viewNav session =
    div [ class "flex mt-4 mx-6 justify-between items-end font-serif" ]
        [ a [ href <| Route.toString Route.Home, class "text-3xl" ] [ text "mitsumori" ]
        , div [ class "flex" ]
            [ case User.userType session.user of
                Authenticated _ ->
                    div [] [ p [ class "text-lg" ] [ text "logout" ], p [ class "text-normal" ] [ text <| "Logged in as " ++ User.username session.user ] ]

                Unauthenticated ->
                    div []
                        [ a [ href <| Route.toString Route.Signup, class "text-lg mr-4" ] [ text "signup" ]
                        , a [ href <| Route.toString Route.Signin, class "text-lg mr-4" ] [ text "signin" ]
                        ]
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
subscriptions model =
    let
        subpageSubs =
            case model.page of
                HomePage home ->
                    Sub.map HomeMsg (Home.subscriptions home)

                Signup signUp ->
                    Sub.map SignupMsg (Signup.subscriptions signUp)

                Signin signIn ->
                    Sub.map SigninMsg (Signin.subscriptions signIn)

                _ ->
                    Sub.none
    in
    Sub.batch [ subpageSubs, Supabase.sessionResponse GotSessionResponse ]
