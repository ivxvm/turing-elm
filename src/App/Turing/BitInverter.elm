module App.Turing.BitInverter exposing (..)

import Core.Direction exposing (Direction(..))
import Core.KeyedTape as KeyedTape
import Core.Rule exposing (Rule)
import Core.Turing exposing (Turing)


turing : Turing String String
turing =
    { tape =
        KeyedTape.fromTape
            { left = [ "1", "0", "1", "{" ]
            , right = [ "1", "1", "0", "1", "}" ]
            , currentSymbol = "0"
            , emptySymbol = "_"
            }
    , currentState = "<<"
    , finalState = "X"
    , rules =
        [ Rule "<<" "0" "0" "<<" Left
        , Rule "<<" "1" "1" "<<" Left
        , Rule "<<" "{" "{" "~>" Right
        , Rule "~>" "0" "1" "~>" Right
        , Rule "~>" "1" "0" "~>" Right
        , Rule "~>" "}" "}" "X" Left
        ]
    }
