module App.Turing.BitInverter exposing (..)

import Core.Direction exposing (Direction(..))
import Core.KeyedTape as KeyedTape
import Core.Rule exposing (Rule)
import Core.Turing exposing (Turing)


turing : Turing String String
turing =
    { tape =
        KeyedTape.fromTape
            { left = []
            , right = [ "1", "1", "0", "1", "1", "0", "1", "0", "1" ]
            , currentSymbol = "0"
            , emptySymbol = "0"
            }
    , currentState = ">>_"
    , finalState = "X"
    , rules =
        [ Rule ">>_" "0" "1" ">>_" Right
        , Rule ">>_" "1" "0" ">>_" Right
        ]
    }
