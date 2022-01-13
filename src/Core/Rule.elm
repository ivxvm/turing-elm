module Core.Rule exposing (..)

import Core.Direction as Direction exposing (Direction)


type alias Rule a s =
    { currentState : s
    , currentSymbol : a
    , newSymbol : a
    , newState : s
    , moveDirection : Direction
    }


toString : (a -> String) -> (s -> String) -> Rule a s -> String
toString symbolToString stateToString rule =
    String.join " "
        [ stateToString rule.currentState
        , symbolToString rule.currentSymbol
        , symbolToString rule.newSymbol
        , stateToString rule.newState
        , Direction.toString rule.moveDirection
        ]


fromString : (String -> a) -> (String -> s) -> String -> Maybe (Rule a s)
fromString symbolFromString stateFromString string =
    Nothing
