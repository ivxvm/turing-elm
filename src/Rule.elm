module Rule exposing (..)

import Direction exposing (Direction)


type alias Rule a s =
    { currentState : s, currentSymbol : a, newSymbol : a, newState : s, moveDirection : Direction }


toString : (a -> String) -> (s -> String) -> Rule a s -> String
toString ap sp rule =
    String.join " "
        [ sp rule.currentState
        , ap rule.currentSymbol
        , ap rule.newSymbol
        , sp rule.newState
        , Direction.toString rule.moveDirection
        ]


fromString : (String -> a) -> (String -> s) -> String -> Maybe (Rule a s)
fromString ap sp string =
    Nothing
