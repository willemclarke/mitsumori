module Components.Button exposing (ButtonType(..), create, view, withAdditionalStyles, withButtonType, withIsDisabled, withIsLoading, withWhiteAppearance)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, disabled, style, type_)
import Html.Events exposing (onClick)
import Html.Extra as HE


type alias Config msg =
    { label : String
    , onClick : msg
    , isLoading : Bool
    , isDisabled : Bool
    , appearence : Appearance
    , additionalStyles : Maybe String
    , type_ : ButtonType
    }


type Button msg
    = Button (Config msg)


type Appearance
    = Black
    | White


type ButtonType
    = Submit
    | Button_


create : { label : String, onClick : msg } -> Button msg
create { label, onClick } =
    Button { label = label, onClick = onClick, isLoading = False, isDisabled = False, appearence = Black, additionalStyles = Nothing, type_ = Submit }


withIsLoading : Bool -> Button msg -> Button msg
withIsLoading isLoading (Button config) =
    Button { config | isLoading = isLoading }


withIsDisabled : Bool -> Button msg -> Button msg
withIsDisabled isDisabled (Button config) =
    Button { config | isDisabled = isDisabled }


withAdditionalStyles : String -> Button msg -> Button msg
withAdditionalStyles additionalStyles (Button config) =
    Button { config | additionalStyles = Just additionalStyles }


withWhiteAppearance : Button msg -> Button msg
withWhiteAppearance (Button config) =
    Button { config | appearence = White }


withButtonType : ButtonType -> Button msg -> Button msg
withButtonType buttonType (Button config) =
    Button { config | type_ = buttonType }


colourSchemeToString : Appearance -> String
colourSchemeToString colour =
    case colour of
        Black ->
            "bg-black text-white"

        White ->
            "bg-white text-black border border-gray-300 hover:border-gray-500 hover:bg-gray-100/90"


buttonTypeToString : ButtonType -> String
buttonTypeToString buttonType =
    case buttonType of
        Submit ->
            "submit"

        Button_ ->
            "button"


spinner : Html msg
spinner =
    div [ style "border-color" "rgba(255, 255, 255, 0.2)", style "border-top-color" "rgba(255,255,255, 0.8)", class "w-5 h-5 border-4 rounded-full animate-spin" ] []


view : Button msg -> Html msg
view (Button ({ label, additionalStyles, isLoading, isDisabled, appearence } as config)) =
    let
        -- TODO, fix disabled state
        appearence_ =
            colourSchemeToString appearence

        classes =
            String.join " "
                [ "py-2 px-4 shadow hover:shadow-md focus:ring focus:ring-slate-300 rounded-md transition ease-in-out hover:-translate-y-0.5 duration-300"
                , appearence_

                -- , isDisabled_
                , Maybe.withDefault "" additionalStyles
                ]
    in
    button
        [ class classes
        , onClick config.onClick
        , disabled isDisabled
        , type_ (buttonTypeToString config.type_)
        ]
        [ div [ class "flex items-center" ]
            [ HE.viewIf isLoading <|
                div [ class "flex items-center justify-center mr-3" ] [ spinner ]
            , text label
            ]
        ]
