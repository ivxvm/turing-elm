module Core.Direction exposing (..)

import Json.Decode as D
import Json.Encode as E


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


encode : Direction -> E.Value
encode direction =
    case direction of
        Left ->
            E.string "left"

        Right ->
            E.string "right"


decoder : D.Decoder Direction
decoder =
    D.string
        |> D.andThen
            (\string ->
                case string of
                    "left" ->
                        D.succeed Left

                    "right" ->
                        D.succeed Right

                    _ ->
                        D.fail ("Incorrect direction: " ++ string)
            )
