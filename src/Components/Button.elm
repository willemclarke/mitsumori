module Components.Button exposing (view)

import Html exposing (Html, button, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


view : { label : String, onClick : msg } -> Html msg
view ({ label } as options) =
    button [ class "py-2 px-4 shadow hover:shadow-md focus:ring focus:ring-slate-300 rounded-md bg-stone-900 text-white", onClick options.onClick ]
        [ text label ]
