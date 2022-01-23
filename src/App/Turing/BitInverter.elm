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
    , currentState = "~>"
    , finalState = "X"
    , rules =
        [ Rule "~>" "0" "1" "~>" Right
        , Rule "~>" "1" "0" "~>" Right
        ]
    }
