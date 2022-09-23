module Route exposing (Route(..), fromUrl)

import Url
import Url.Parser as Parser


type Route
    = Home


parser : Parser.Parser (Route -> a) a
parser =
    Parser.map Home Parser.top


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    Parser.parse parser url
