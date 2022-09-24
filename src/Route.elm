module Route exposing (Route(..), fromUrl)

import Url
import Url.Parser as Parser


type Route
    = Home
    | Signup
    | Login


parser : Parser.Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Signup (Parser.s "signup")
        , Parser.map Login (Parser.s "login")
        ]


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    Parser.parse parser url
