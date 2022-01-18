module Core.Turing exposing (..)

import Basics.Extra exposing (flip)
import Core.KeyedTape as KeyedTape exposing (KeyedTape)
import Core.Rule as Rule exposing (Rule)
import Json.Decode as D
import Json.Encode as E


type alias Turing sym st =
    { tape : KeyedTape {} sym
    , currentState : st
    , finalState : st
    , rules : List (Rule sym st)
    }


setTape : KeyedTape {} a -> Turing a s -> Turing a s
setTape tape turing =
    { turing | tape = tape }


asTapeIn : Turing a s -> KeyedTape {} a -> Turing a s
asTapeIn =
    flip setTape


setRules : List (Rule sym st) -> Turing sym st -> Turing sym st
setRules rules turing =
    { turing | rules = rules }


asRulesIn : Turing sym st -> List (Rule sym st) -> Turing sym st
asRulesIn =
    flip setRules


isHalted : Turing a s -> Bool
isHalted turing =
    turing.currentState == turing.finalState


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


encode : (sym -> E.Value) -> (st -> E.Value) -> Turing sym st -> E.Value
encode encodeSymbol encodeState turing =
    E.object
        [ ( "tape", KeyedTape.encode encodeSymbol turing.tape )
        , ( "currentState", encodeState turing.currentState )
        , ( "finalState", encodeState turing.finalState )
        , ( "rules", E.list (Rule.encode encodeSymbol encodeState) turing.rules )
        ]


encodeSimple : Turing String String -> E.Value
encodeSimple =
    encode E.string E.string


decoder : D.Decoder sym -> D.Decoder st -> D.Decoder (Turing sym st)
decoder symbolDecoder stateDecoder =
    D.map4 Turing
        (D.field "tape" (KeyedTape.decoder symbolDecoder))
        (D.field "currentState" stateDecoder)
        (D.field "finalState" stateDecoder)
        (D.field "rules" (D.list (Rule.decoder symbolDecoder stateDecoder)))


decoderSimple : D.Decoder (Turing String String)
decoderSimple =
    decoder D.string D.string
