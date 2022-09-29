module Router.Route exposing (..)

import Browser.Navigation as Nav
import Url
import Url.Parser as Parser


type Route
    = Home
    | Signup
    | Signin
    | NotFound


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


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    Parser.parse parser url
