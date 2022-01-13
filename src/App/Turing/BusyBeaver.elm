module App.Turing.BusyBeaver exposing (..)

import Core.Direction exposing (Direction(..))
import Core.Rule exposing (Rule)
import Core.Turing exposing (Turing)


turing : Turing String String
turing =
    { tape = { left = [], right = [], currentSymbol = "0", emptySymbol = "0" }
    , currentState = "A"
    , isFinalState = \s -> s == "X"
    , rules =
        [ Rule "A" "1" "1" "C" Left
        , Rule "A" "0" "1" "B" Right
        , Rule "B" "0" "1" "A" Left
        , Rule "B" "1" "1" "B" Right
        , Rule "C" "0" "1" "B" Left
        , Rule "C" "1" "1" "X" Right
        ]
    }
