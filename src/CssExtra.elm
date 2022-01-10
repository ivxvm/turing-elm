module CssExtra exposing (..)

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (class)


classIf : Bool -> String -> Attribute msg
classIf condition className =
    if condition then
        class className

    else
        class ""
