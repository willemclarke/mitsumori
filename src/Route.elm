module Route exposing (Route(..), fromUrl)

import Url
import Url.Parser as Parser


type Route
    = Home
    | Signup
    | Signin


parser : Parser.Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Signup (Parser.s "signup")
        , Parser.map Signin (Parser.s "signin")
        ]


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    Parser.parse parser url
