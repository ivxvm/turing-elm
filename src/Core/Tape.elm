module Core.Tape exposing (..)

import Core.Direction exposing (Direction(..))


type alias Tape a =
    { left : List a
    , right : List a
    , currentSymbol : a
    , emptySymbol : a
    }


shiftLeft : Tape a -> Tape a
shiftLeft tape =
    case tape.left of
        x :: xs ->
            { tape | left = xs, right = tape.currentSymbol :: tape.right, currentSymbol = x }

        [] ->
            { tape
                | right = tape.currentSymbol :: tape.right
                , currentSymbol = tape.emptySymbol
            }


shiftRight : Tape a -> Tape a
shiftRight tape =
    case tape.right of
        x :: xs ->
            { tape | left = tape.currentSymbol :: tape.left, right = xs, currentSymbol = x }

        [] ->
            { tape
                | left = tape.currentSymbol :: tape.left
                , currentSymbol = tape.emptySymbol
            }


shift : Direction -> Tape a -> Tape a
shift direction tape =
    case direction of
        Left ->
            shiftLeft tape

        Right ->
            shiftRight tape


writeSymbol : a -> Tape a -> Tape a
writeSymbol newSymbol tape =
    { tape | currentSymbol = newSymbol }


toSymbolList : Int -> Tape a -> ( List a, Int )
toSymbolList minSize tape =
    let
        leftLen =
            List.length tape.left

        sizeToPad =
            minSize - leftLen - 1 - List.length tape.right

        halfPadding =
            sizeToPad // 2

        paddingSublist =
            List.repeat halfPadding tape.emptySymbol

        symbols =
            List.concat
                [ paddingSublist
                , tape.left
                , [ tape.currentSymbol ]
                , tape.right
                , paddingSublist
                , List.repeat (modBy sizeToPad 2) tape.emptySymbol
                ]

        currentSymbolIndex =
            halfPadding + leftLen
    in
    ( symbols, currentSymbolIndex )
