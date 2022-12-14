module Components.Dropdown exposing (create, view)

import Heroicons.Outline as HeroIcons
import Html exposing (Html, button, div, option, span, text)
import Html.Attributes exposing (class, id, tabindex, type_)
import Html.Attributes.Aria exposing (ariaExpanded, ariaHasPopup, ariaLabelledby, role)
import Html.Events exposing (onBlur, onClick, onMouseDown, preventDefaultOn)
import Html.Extra as HE
import Json.Decode as JD
import Svg.Attributes as SvgAttr
import User


type alias Config msg =
    { user : User.UserInfo
    , onClick : msg
    , onBlur : msg
    , isOpen : Bool
    , options : List (Option msg)
    }


type alias Option msg =
    { label : String
    , onClick : msg
    , icon : Maybe (Html msg)
    }


type Dropdown msg
    = Dropdown (Config msg)


create : Config msg -> Dropdown msg
create config =
    Dropdown config


view : Dropdown msg -> Html msg
view (Dropdown ({ user, options, isOpen } as config)) =
    let
        ariaExpanded_ =
            if isOpen then
                "true"

            else
                "false"
    in
    div
        [ class "relative inline-block text-left font-sans"
        ]
        [ div []
            [ button
                [ class "flex items-center py-2 px-4 bg-white text-black border border-gray-300 hover:border-gray-500 hover:bg-gray-100/90 shadow hover:shadow-md focus:outline-none focus:ring focus:ring-slate-300 rounded-md"
                , type_ "button"
                , id "menu-button"
                , ariaExpanded ariaExpanded_
                , ariaHasPopup "true"
                , onClick config.onClick
                , onBlur config.onBlur
                ]
                [ text user.username
                , span [ class "ml-1" ] [ HeroIcons.chevronDown [ SvgAttr.class "w-5 h-5" ] ]
                ]
            ]
        , HE.viewIf isOpen
            (div
                [ class "absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none animate-in fade-in duration-400"
                , role "menu"
                , ariaLabelledby "menu-button"
                , tabindex -1
                ]
                [ div
                    [ class "flex flex-col text-gray-700 text-sm my-1"
                    , role "none"
                    ]
                    -- header
                    [ div [ class "px-4 py-2 font-normal border-b" ]
                        [ text "Signed in as ", span [ class "font-semibold" ] [ text user.email ] ]

                    -- options
                    , div []
                        (List.map
                            (\option ->
                                div
                                    [ class "flex items-center block px-4 py-2 hover:bg-gray-100/60 cursor-pointer"
                                    , onMouseDown option.onClick
                                    , preventDefaultOn "mousedown" (JD.succeed ( option.onClick, True ))
                                    , onClick config.onBlur
                                    , tabindex -1
                                    , role "menuitem"
                                    ]
                                    [ HE.viewMaybe (\icon -> span [ class "mr-2" ] [ icon ]) option.icon
                                    , text option.label
                                    ]
                            )
                            options
                        )
                    ]
                ]
            )
        ]
