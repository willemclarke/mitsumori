module Components.Button exposing (create, view, withAdditionalStyles, withIsDisabled, withIsLoading)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, disabled, style, type_)
import Html.Events exposing (onClick)
import Html.Extra as HE


type alias Config msg =
    { label : String
    , onClick : msg
    , isLoading : Bool
    , isDisabled : Bool
    , additionalStyles : Maybe String
    }


type Button msg
    = Button (Config msg)


create : { label : String, onClick : msg } -> Button msg
create { label, onClick } =
    Button { label = label, onClick = onClick, isLoading = False, isDisabled = False, additionalStyles = Nothing }


withIsLoading : Bool -> Button msg -> Button msg
withIsLoading isLoading (Button config) =
    Button { config | isLoading = isLoading }


withIsDisabled : Bool -> Button msg -> Button msg
withIsDisabled isDisabled (Button config) =
    Button { config | isDisabled = isDisabled }


withAdditionalStyles : String -> Button msg -> Button msg
withAdditionalStyles additionalStyles (Button config) =
    Button { config | additionalStyles = Just additionalStyles }


spinner : Html msg
spinner =
    div [ style "border-color" "rgba(255, 255, 255, 0.2)", style "border-top-color" "rgba(255,255,255, 0.8)", class "w-5 h-5 border-4 rounded-full animate-spin" ] []


view : Button msg -> Html msg
view (Button ({ label, additionalStyles, isLoading, isDisabled } as config)) =
    let
        isDisabled_ =
            if isDisabled then
                "bg-stone-900/60"

            else
                "bg-stone-900"

        classes =
            String.join " "
                [ "py-2 px-4 shadow hover:shadow-md focus:ring focus:ring-slate-300 rounded-md bg-stone-900 text-white"
                , isDisabled_
                , Maybe.withDefault "" additionalStyles
                ]
    in
    button
        [ class classes
        , onClick config.onClick
        , disabled isDisabled
        , type_ "submit"
        ]
        [ div [ class "flex items-center" ]
            [ HE.viewIf isLoading <|
                div [ class "flex items-center justify-center mr-3" ] [ spinner ]
            , text label
            ]
        ]
