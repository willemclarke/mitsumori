module Components.Button exposing (create, view, withAdditionalStyles, withIsDisabled)

import Html exposing (Html, button, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)


type alias Config msg =
    { label : String
    , onClick : msg
    , isDisabled : Bool
    , additionalStyles : Maybe String
    }


type Button msg
    = Button (Config msg)


create : { label : String, onClick : msg } -> Button msg
create { label, onClick } =
    Button { label = label, onClick = onClick, isDisabled = False, additionalStyles = Nothing }


withIsDisabled : Bool -> Button msg -> Button msg
withIsDisabled isDisabled (Button config) =
    Button { config | isDisabled = isDisabled }


withAdditionalStyles : String -> Button msg -> Button msg
withAdditionalStyles additionalStyles (Button config) =
    Button { config | additionalStyles = Just additionalStyles }


view : Button msg -> Html msg
view (Button ({ label, additionalStyles, isDisabled } as config)) =
    let
        classes =
            String.join " "
                [ "py-2 px-4 shadow hover:shadow-md focus:ring focus:ring-slate-300 rounded-md bg-stone-900 text-white"
                , Maybe.withDefault "" additionalStyles
                ]
    in
    button [ class classes, onClick config.onClick, disabled isDisabled ]
        [ text label ]
