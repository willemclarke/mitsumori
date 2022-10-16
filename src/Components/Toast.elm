module Components.Toast exposing (ToastType(..), error, region, success, view)

import Components.Icons as Icons
import Html exposing (Html, button, div, p, span, text)
import Html.Attributes exposing (attribute, class)
import Html.Events exposing (onClick)


type ToastType
    = Success String
    | Error String


success : String -> ToastType
success message =
    Success message


error : String -> ToastType
error message =
    Error message


messageToBody : String -> Html msg
messageToBody message =
    p [] [ text message ]


viewSuccess : String -> msg -> Html msg
viewSuccess message onClose =
    viewToast Icons.delete (messageToBody message) onClose


viewError : String -> msg -> Html msg
viewError message onClose =
    viewToast Icons.delete (messageToBody message) onClose


viewToast : Html msg -> Html msg -> msg -> Html msg
viewToast icon body onClose =
    div
        [ class "transform translate-y-2 animate-slide-in bg-white shadow-lg rounded-lg pointer-events-auto ring-1 ring-black ring-opacity-5 overflow-hidden"
        ]
        [ div
            [ class "p-4"
            ]
            [ div
                [ class "flex items-center"
                ]
                [ div
                    [ class "flex-shrink-0"
                    ]
                    [ icon
                    ]
                , div
                    [ class "ml-3 flex-1"
                    ]
                    [ body
                    ]
                , div
                    [ class "ml-4 flex-shrink-0 flex"
                    ]
                    [ button
                        [ class "bg-white rounded-md inline-flex text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        , onClick onClose
                        ]
                        [ span [ class "sr-only" ] [ text "Close" ]
                        , Icons.delete
                        ]
                    ]
                ]
            ]
        ]


region : List (Html msg) -> Html msg
region snackbars =
    div
        [ attribute "aria-live" "assertive"
        , class "fixed inset-0 flex items-end px-4 py-6 pointer-events-none"
        ]
        [ div [ class "w-full flex flex-col items-center space-y-4" ] snackbars
        ]


view : ToastType -> msg -> Html msg
view toastType onClose =
    case toastType of
        Success message ->
            viewSuccess message onClose

        Error message ->
            viewError message onClose
