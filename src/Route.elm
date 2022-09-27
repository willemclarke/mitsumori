module Route exposing (Route(..), fromUrl, replaceUrl, toString)

import Browser.Navigation as Nav
import Url
import Url.Parser as Parser


type Route
    = Home
    | Signup
    | Signin


toString : Route -> String
toString route =
    case route of
        Home ->
            "/"

        Signup ->
            "signup"

        Signin ->
            "signin"


parser : Parser.Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Signup (Parser.s "signup")
        , Parser.map Signin (Parser.s "signin")
        ]


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (toString route)


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    Parser.parse parser url
