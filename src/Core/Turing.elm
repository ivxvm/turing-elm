module Core.Turing exposing (..)

import Basics.Extra exposing (flip)
import Core.KeyedTape as KeyedTape exposing (KeyedTape)
import Core.Rule exposing (Rule)


type alias Turing a s =
    { tape : KeyedTape {} a
    , currentState : s
    , isFinalState : s -> Bool
    , rules : List (Rule a s)
    }


setTape : KeyedTape {} a -> Turing a s -> Turing a s
setTape tape turing =
    { turing | tape = tape }


asTapeIn : Turing a s -> KeyedTape {} a -> Turing a s
asTapeIn =
    flip setTape


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
                        |> KeyedTape.writeSymbol newSymbol
                        |> KeyedTape.shift moveDirection
                , currentState = newState
            }
