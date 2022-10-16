module User exposing (User, UserInfo, UserType(..), decoder, isAuthenticated, unauthenticated, userId, userJwt, userType, username)

import Json.Decode as JD
import Uuid


type User
    = User UserType


type UserType
    = Authenticated UserInfo
    | Unauthenticated


type alias UserInfo =
    { jwt : String
    , email : String
    , username : String
    , id : String
    }


decoder : JD.Decoder User
decoder =
    userDecoder
        |> JD.andThen
            (\userInfo ->
                case userInfo.jwt of
                    "" ->
                        JD.succeed (User Unauthenticated)

                    _ ->
                        JD.succeed <| User (Authenticated userInfo)
            )


userDecoder : JD.Decoder UserInfo
userDecoder =
    JD.map4 UserInfo
        (JD.field "access_token" JD.string)
        (JD.field "user" (JD.field "email" JD.string))
        (JD.field "user" (JD.field "user_metadata" (JD.field "username" JD.string)))
        (JD.field "user" (JD.field "id" JD.string))


userJwt : User -> String
userJwt (User type_) =
    case type_ of
        Authenticated userInfo ->
            userInfo.jwt

        Unauthenticated ->
            ""


userType : User -> UserType
userType (User type_) =
    type_


userId : User -> Maybe String
userId (User type_) =
    case type_ of
        Authenticated userInfo ->
            Just userInfo.id

        Unauthenticated ->
            Nothing


isAuthenticated : User -> Bool
isAuthenticated (User type_) =
    case type_ of
        Authenticated _ ->
            True

        Unauthenticated ->
            False


unauthenticated : User
unauthenticated =
    User Unauthenticated


username : User -> String
username (User type_) =
    case type_ of
        Authenticated user ->
            user.username

        Unauthenticated ->
            ""
