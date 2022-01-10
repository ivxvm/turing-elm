module Utils.AttributeExtra exposing (..)

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (class, classList)
import Html.Styled.Events exposing (onClick)


classIf : Bool -> String -> Attribute msg
classIf condition className =
    if condition then
        class className

    else
        class ""


onClickIf : Bool -> msg -> Attribute msg
onClickIf cond msg =
    if cond then
        onClick msg

    else
        classList []
