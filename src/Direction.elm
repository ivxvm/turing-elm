module Direction exposing (..)


type Direction
    = Left
    | Right


toString : Direction -> String
toString direction =
    case direction of
        Left ->
            "L"

        Right ->
            "R"


fromString : String -> Maybe Direction
fromString string =
    case string of
        "L" ->
            Just Left

        "R" ->
            Just Right

        _ ->
            Nothing
