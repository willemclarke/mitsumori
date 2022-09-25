module User exposing (..)

import Json.Decode as JD


type alias UserInfo =
    { jwt : String
    , email : String
    , username : String
    , id : String
    }


type UserType
    = Authenticated UserInfo
    | Unauthenticated


type User
    = User UserType


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
