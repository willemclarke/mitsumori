module Router.Route exposing (..)

import Browser.Navigation as Nav
import Url
import Url.Parser as Parser
import User exposing (User, UserType(..))


type Route
    = Home
    | Signup
    | Signin
    | NotFound


checkNav : User -> Maybe Route -> Maybe Route
checkNav user route =
    let
        userType =
            User.userType user
    in
    case ( userType, route ) of
        ( Authenticated _, Just Home ) ->
            Just Home

        ( Unauthenticated, Just Home ) ->
            Just Signup

        ( Unauthenticated, Just Signin ) ->
            Just Signin

        ( Unauthenticated, Just Signup ) ->
            Just Signup

        ( Unauthenticated, Just NotFound ) ->
            Just NotFound

        ( Authenticated _, Just NotFound ) ->
            Just NotFound

        ( _, _ ) ->
            Just NotFound


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


parser : Parser.Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Signup (Parser.s "signup")
        , Parser.map Signin (Parser.s "signin")
        ]


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    Nav.pushUrl key (toString route)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (toString route)


toString : Route -> String
toString route =
    case route of
        Home ->
            "/"

        Signup ->
            "signup"

        Signin ->
            "signin"

        _ ->
            ""


toTitleString : Route -> String
toTitleString route =
    case route of
        Home ->
            "Home"

        Signup ->
            "Signup"

        Signin ->
            "Signin"

        NotFound ->
            "Not Found"
