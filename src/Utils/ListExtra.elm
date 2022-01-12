module Utils.ListExtra exposing (..)


updateLast : (a -> a) -> List a -> List a
updateLast f l =
    case l of
        [] ->
            []

        x :: [] ->
            [ f x ]

        x :: xs ->
            x :: updateLast f xs
