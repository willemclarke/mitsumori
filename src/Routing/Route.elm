module Routing.Route exposing (Filter, Route(..), appendFilterParams, checkNav, emptyFilter, extractFilterParams, filterQueryParams, fromUrl, pushUrl, replaceUrl, toString, toTitleString)

import Browser.Navigation as Nav
import Html exposing (a)
import Maybe.Extra as ME
import Url
import Url.Builder as Builder
import Url.Parser as Parser exposing ((</>), (<?>))
import Url.Parser.Query as Query
import User exposing (User, UserType(..))


type Route
    = Home Filter
    | Profile String
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
        , Parser.map Profile (Parser.s "profile" </> profileIdParser)
        , Parser.map Signup (Parser.s "signup")
        , Parser.map Signin (Parser.s "signin")
        ]


profileIdParser : Parser.Parser (String -> a) a
profileIdParser =
    Parser.custom "profile" (\str -> Just str)


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


toString : Route -> String
toString route =
    case route of
        Home _ ->
            "/"

        Profile id ->
            "/profile/" ++ id

        Signup ->
            "signup"

        Signin ->
            "signin"

        _ ->
            ""


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

        ( Authenticated _, Just (Profile id) ) ->
            Just (Profile id)

        ( Unauthenticated, Just (Profile _) ) ->
            Just Signin

        ( Authenticated _, Just Signin ) ->
            Just (Home emptyFilter)

        ( Authenticated _, Just Signup ) ->
            Just (Home emptyFilter)

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


toTitleString : Route -> String
toTitleString route =
    case route of
        Home _ ->
            "Home"

        Profile _ ->
            "Profile"

        Signup ->
            "Signup"

        Signin ->
            "Signin"

        NotFound ->
            "Not Found"
