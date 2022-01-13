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


padLeft : Int -> a -> List a -> List a
padLeft count padElem list =
    case count of
        0 ->
            list

        n ->
            padLeft (n - 1) padElem (padElem :: list)


padRight : Int -> a -> List a -> List a
padRight count padElem list =
    list ++ List.repeat count padElem
