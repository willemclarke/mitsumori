module Components.Modal exposing (acceptAndDiscardActions, asyncAction, basicAction, create, view)

import Components.Button as Button
import Html exposing (Html, div, header, p, span, text)
import Html.Attributes exposing (attribute, class, id)
import Html.Events exposing (onClick)
import RemoteData exposing (isLoading)


type Modal msg
    = Modal (Options msg)


type alias Options msg =
    { title : String
    , body : Html msg
    , actions : Actions msg
    }


type Action msg
    = Action { label : String, onClick : msg, isLoading : Bool }


type Actions msg
    = Actions { accept : Action msg, cancel : Action msg }


pickAcceptAction : Actions msg -> Action msg
pickAcceptAction (Actions { accept }) =
    accept


pickCancelAction : Actions msg -> Action msg
pickCancelAction (Actions { cancel }) =
    cancel


create : Options msg -> Modal msg
create { title, body, actions } =
    Modal { title = title, body = body, actions = actions }


basicAction : String -> msg -> Action msg
basicAction label onClick =
    Action { label = label, onClick = onClick, isLoading = False }


asyncAction : { label : String, onClick : msg, isLoading : Bool } -> Action msg
asyncAction { label, onClick, isLoading } =
    Action { label = label, onClick = onClick, isLoading = isLoading }


acceptAndDiscardActions : Action msg -> Action msg -> Actions msg
acceptAndDiscardActions accept cancel =
    Actions { accept = accept, cancel = cancel }


acceptButton : Action msg -> Html msg
acceptButton (Action { label, onClick, isLoading }) =
    Button.create { label = label, onClick = onClick }
        |> Button.withAdditionalStyles "my-2 sm:mx-2"
        |> Button.withIsLoading isLoading
        |> Button.view


cancelButton : Action msg -> Html msg
cancelButton (Action { label, onClick }) =
    Button.create { label = label, onClick = onClick }
        |> Button.withAdditionalStyles "sm:my-2"
        |> Button.withWhiteAppearance
        |> Button.view


view : Modal msg -> Html msg
view (Modal options) =
    let
        acceptAction =
            pickAcceptAction options.actions

        cancelAction =
            pickCancelAction options.actions

        acceptButton_ =
            acceptButton acceptAction

        cancelButton_ =
            cancelButton cancelAction
    in
    div
        [ class "fixed inset-0 z-10 overflow-y-auto"
        , attribute "aria-labelledby" "modal-title"
        , attribute "role" "dialog"
        , attribute "aria-modal" "true"
        ]
        [ div
            [ class "flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0"
            ]
            [ div
                [ class "fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
                , attribute "aria-hidden" "true"
                ]
                []

            {- This element is to trick the browser into centering the modal contents. -}
            , span
                [ class "hidden sm:inline-block sm:align-middle sm:h-screen"
                , attribute "aria-hidden" "true"
                ]
                [ text "\u{200B}" ]
            , div
                [ class "inline-block px-4 pt-5 pb-4 overflow-hidden text-left align-bottom bg-white rounded-xl shadow-lg transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6"
                ]
                [ div
                    [ class "sm:flex sm:items-start"
                    ]
                    [ div
                        [ class "mt-3 text-center sm:mt-0 sm:text-left flex flex-col grow"
                        ]
                        [ header
                            [ class "text-2xl mb-6 font-medium font-serif"
                            , id "modal-title"
                            ]
                            [ text options.title ]
                        , div
                            [ class "text-left my-2"
                            ]
                            [ p
                                [ class "text-gray-500"
                                ]
                                [ options.body ]
                            ]
                        ]
                    ]
                , div
                    [ class "flex flex-col mt-9 mb-2 sm:flex-row-reverse"
                    ]
                    [ acceptButton_
                    , cancelButton_
                    ]
                ]
            ]
        ]
