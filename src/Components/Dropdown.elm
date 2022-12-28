module Components.Dropdown exposing (create, view)

import Components.Button as Button
import Html exposing (Html, a, button, div, option, text)
import Html.Attributes exposing (class, id, tabindex, type_)
import Html.Attributes.Aria exposing (ariaExpanded, ariaHasPopup, ariaLabelledby, role)
import Html.Events exposing (onClick)
import Html.Extra as HE


type alias Config msg =
    { username : String
    , onClick : msg
    , isOpen : Bool
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
view (Dropdown ({ username, options, isOpen } as config)) =
    let
        ariaExpanded_ =
            if isOpen then
                "true"

            else
                "false"
    in
    div
        [ class "relative inline-block text-left"
        ]
        [ div []
            [ button
                [ class "font-sans py-2 px-4 bg-white text-black border border-gray-300 hover:border-gray-500 hover:bg-gray-100/90 shadow hover:shadow-md focus:ring focus:ring-slate-300 rounded-md"
                , type_ "button"
                , id "menu-button"
                , ariaExpanded ariaExpanded_
                , ariaHasPopup "true"
                , onClick config.onClick
                ]
                [ text username ]
            ]
        , HE.viewIf isOpen
            (div
                [ class "absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none transition-opacity"
                , role "menu"
                , ariaLabelledby "menu-button"
                , tabindex -1
                ]
                [ div [ class "flex flex-col p-1 font-sans", role "none" ]
                    (List.map
                        (\option ->
                            a
                                [ class "text-gray-700 block px-4 py-2 text-sm hover:bg-gray-100/60"
                                , onClick option.onClick
                                , tabindex -1
                                , role "menuitem"
                                ]
                                [ text option.label ]
                        )
                        options
                    )
                ]
            )
        ]
