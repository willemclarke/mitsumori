module User exposing (User, UserInfo, UserType(..), decoder, unauthenticated, userType, username)

import Json.Decode as JD


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


userType : User -> UserType
userType (User type_) =
    type_


unauthenticated : User
unauthenticated =
    User Unauthenticated


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
        (JD.field "user" (JD.field "id" JD.string))
        (JD.field "user" (JD.field "email" JD.string))
        (JD.field "user" (JD.field "user_metadata" (JD.field "username" JD.string)))


username : User -> String
username (User type_) =
    case type_ of
        Authenticated user ->
            user.username

        Unauthenticated ->
            ""
