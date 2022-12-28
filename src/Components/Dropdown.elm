module Components.Dropdown exposing (create, view)

import Components.Button as Button
import Html exposing (Html, a, button, div, option, text)
import Html.Attributes exposing (class, disabled, href, style, tabindex, type_)
import Html.Events exposing (onClick)
import Html.Extra as HE


type alias Config msg =
    { username : String
    , onClick : msg
    , options : List (Option msg)
    }


type alias Option msg =
    { label : String
    , onClick : msg
    }


type Dropdown msg
    = Dropdown (Config msg)


create : Config msg -> Dropdown msg
create config =
    Dropdown config


view : Dropdown msg -> Html msg
view (Dropdown ({ username, options } as config)) =
    div [ class "relative inline-block text-left" ]
        [ div []
            [ Button.create { label = username, onClick = config.onClick }
                |> Button.withWhiteAppearance
                |> Button.withAdditionalStyles "font-sans"
                |> Button.withButtonType Button.Button_
                |> Button.view
            ]
        , div
            [ class "absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
            , tabindex -1
            ]
            [ div [ class "p-1 font-sans" ]
                (List.map
                    (\option ->
                        a
                            [ class "text-gray-700 block px-4 py-2 text-sm hover:bg-gray-100/30"
                            , onClick option.onClick
                            , tabindex -1
                            ]
                            [ text option.label ]
                    )
                    options
                )
            ]
        ]
