module Routing.Route exposing (Filter, Route(..), appendFilterParams, checkNav, emptyFilter, extractFilterParams, filterQueryParams, fromUrl, pushUrl, replaceUrl, toString, toTitleString)

import Browser.Navigation as Nav
import Maybe.Extra as ME
import Url
import Url.Builder as Builder
import Url.Parser as Parser exposing ((</>), (<?>))
import Url.Parser.Query as Query
import User exposing (User, UserType(..))


type Route
    = Home Filter
    | Signup
    | Signin
    | NotFound


type alias Filter =
    { searchTerm : Maybe String
    }


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


parser : Parser.Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home (Parser.top <?> filterQueryParams)
        , Parser.map Signup (Parser.s "signup")
        , Parser.map Signin (Parser.s "signin")
        ]


filterQueryParams : Query.Parser Filter
filterQueryParams =
    Query.map Filter (Query.string "search")


extractFilterParams : Url.Url -> Filter
extractFilterParams url =
    fromUrl url
        |> Maybe.map
            (\route ->
                case route of
                    Home filter ->
                        filter

                    _ ->
                        emptyFilter
            )
        |> Maybe.withDefault emptyFilter


emptyFilter : Filter
emptyFilter =
    { searchTerm = Nothing }


appendFilterParams : Nav.Key -> Filter -> Cmd msg
appendFilterParams key filter =
    Nav.replaceUrl key (Builder.absolute [] (parseParams filter))


parseParams : Filter -> List Builder.QueryParameter
parseParams filter =
    ME.values
        [ Maybe.map (Builder.string "search") filter.searchTerm
        ]


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    Nav.pushUrl key (toString route)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (toString route)


checkNav : User -> Maybe Route -> Maybe Route
checkNav user route =
    let
        userType =
            User.userType user
    in
    case ( userType, route ) of
        ( Authenticated _, Just (Home filter) ) ->
            Just (Home filter)

        ( Unauthenticated, Just (Home _) ) ->
            Just Signin

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


toString : Route -> String
toString route =
    case route of
        Home _ ->
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
        Home _ ->
            "Home"

        Signup ->
            "Signup"

        Signin ->
            "Signin"

        NotFound ->
            "Not Found"
