module Core.Rule exposing (..)

import Core.Direction as Direction exposing (Direction)
import Json.Decode as D
import Json.Encode as E


type alias Rule sym st =
    { currentState : st
    , currentSymbol : sym
    , newSymbol : sym
    , newState : st
    , moveDirection : Direction
    }


toString : (sym -> String) -> (st -> String) -> Rule sym st -> String
toString symbolToString stateToString rule =
    String.join " "
        [ stateToString rule.currentState
        , symbolToString rule.currentSymbol
        , symbolToString rule.newSymbol
        , stateToString rule.newState
        , Direction.toString rule.moveDirection
        ]


fromString : (String -> sym) -> (String -> st) -> String -> Maybe (Rule sym st)
fromString symbolFromString stateFromString string =
    let
        parts =
            String.split " " string
                |> List.filter (not << String.isEmpty)
    in
    case parts of
        [ currentStateString, currentSymbolString, newSymbolString, newStateString, moveDirectionString ] ->
            Direction.fromString moveDirectionString
                |> Maybe.map
                    (\direction ->
                        { currentState = stateFromString currentStateString
                        , currentSymbol = symbolFromString currentSymbolString
                        , newSymbol = symbolFromString newSymbolString
                        , newState = stateFromString newStateString
                        , moveDirection = direction
                        }
                    )

        _ ->
            Nothing


encode : (sym -> E.Value) -> (st -> E.Value) -> Rule sym st -> E.Value
encode encodeSymbol encodeState rule =
    E.object
        [ ( "currentState", encodeState rule.currentState )
        , ( "currentSymbol", encodeSymbol rule.currentSymbol )
        , ( "newSymbol", encodeSymbol rule.newSymbol )
        , ( "newState", encodeState rule.newState )
        , ( "moveDirection", Direction.encode rule.moveDirection )
        ]


decoder : D.Decoder sym -> D.Decoder st -> D.Decoder (Rule sym st)
decoder symbolDecoder stateDecoder =
    D.map5 Rule
        (D.field "currentState" stateDecoder)
        (D.field "currentSymbol" symbolDecoder)
        (D.field "newSymbol" symbolDecoder)
        (D.field "newState" stateDecoder)
        (D.field "moveDirection" Direction.decoder)
