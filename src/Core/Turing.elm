module Core.Turing exposing (..)

import Core.Rule exposing (Rule)
import Core.Tape as Tape exposing (Tape)


type alias Turing a s =
    { tape : Tape a
    , currentState : s
    , isFinalState : s -> Bool
    , rules : List (Rule a s)
    }


isHalted : Turing a s -> Bool
isHalted turing =
    turing.isFinalState turing.currentState


findApplicableRule : Turing a s -> Maybe ( Int, Rule a s )
findApplicableRule turing =
    let
        recurse rules index =
            case rules of
                ({ currentState, currentSymbol } as r) :: rs ->
                    if (turing.currentState == currentState) && (turing.tape.currentSymbol == currentSymbol) then
                        Just ( index, r )

                    else
                        recurse rs (index + 1)

                [] ->
                    Nothing
    in
    recurse turing.rules 0


applyRule : Rule a s -> Turing a s -> Maybe (Turing a s)
applyRule { currentState, currentSymbol, newSymbol, newState, moveDirection } turing =
    if turing.currentState /= currentState || turing.tape.currentSymbol /= currentSymbol then
        Nothing

    else
        Just
            { turing
                | tape =
                    turing.tape
                        |> Tape.writeSymbol newSymbol
                        |> Tape.shift moveDirection
                , currentState = newState
            }
