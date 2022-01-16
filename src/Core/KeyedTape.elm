module Core.KeyedTape exposing (..)

import Basics.Extra exposing (flip)
import Core.Direction as Direction exposing (Direction)
import Core.Tape as Tape exposing (Tape)
import Json.Decode as D
import Json.Encode as E


type alias KeyedTape ext sym =
    Tape
        { ext
            | keysTape : Tape {} Int
            , keysCounter : Int
        }
        sym


setEmptySymbol : sym -> KeyedTape ext sym -> KeyedTape ext sym
setEmptySymbol =
    Tape.setEmptySymbol


asEmptySymbolIn : KeyedTape ext sym -> sym -> KeyedTape ext sym
asEmptySymbolIn =
    flip setEmptySymbol


shift : Direction -> KeyedTape ext sym -> KeyedTape ext sym
shift dir tape =
    let
        newTape =
            Tape.shift dir tape

        shiftedKeysTape =
            Tape.shift dir tape.keysTape

        needsNewKey =
            shiftedKeysTape.currentSymbol == shiftedKeysTape.emptySymbol

        newKeysTape =
            { shiftedKeysTape
                | currentSymbol =
                    if needsNewKey then
                        tape.keysCounter

                    else
                        shiftedKeysTape.currentSymbol
            }

        newKeysCounter =
            if needsNewKey then
                tape.keysCounter + 1

            else
                tape.keysCounter
    in
    { newTape
        | keysTape = newKeysTape
        , keysCounter = newKeysCounter
    }


lookahead : KeyedTape ext sym -> KeyedTape ext sym
lookahead tape =
    -- useful to reserve draft neighbour cells for smooth css transitions
    tape
        |> shift Direction.Right
        |> shift Direction.Left
        |> shift Direction.Left
        |> shift Direction.Right


writeSymbol : sym -> KeyedTape ext sym -> KeyedTape ext sym
writeSymbol =
    Tape.writeSymbol


currentSymbolIndex : KeyedTape ext sym -> Int
currentSymbolIndex =
    Tape.currentSymbolIndex


toSymbolList : KeyedTape ext sym -> List sym
toSymbolList =
    Tape.toSymbolList


toKeyList : KeyedTape ext sym -> List Int
toKeyList tape =
    List.concat
        [ List.reverse tape.keysTape.left
        , [ tape.keysTape.currentSymbol ]
        , tape.keysTape.right
        ]


fromTape : Tape {} sym -> KeyedTape {} sym
fromTape tape =
    let
        leftLen =
            List.length tape.left
    in
    { left = tape.left
    , right = tape.right
    , currentSymbol = tape.currentSymbol
    , emptySymbol = tape.emptySymbol
    , keysTape =
        { left = List.indexedMap (\i _ -> i) tape.left
        , right = List.indexedMap (\i _ -> leftLen + i + 1) tape.right
        , currentSymbol = leftLen
        , emptySymbol = -1
        }
    , keysCounter = leftLen + List.length tape.right + 1
    }


fromString : (String -> Maybe sym) -> sym -> String -> Result String (KeyedTape {} sym)
fromString parseSymbol emptySymbol string =
    string
        |> Tape.fromString parseSymbol emptySymbol
        |> Result.map fromTape


toTapeString : (sym -> String) -> KeyedTape ext sym -> String
toTapeString =
    Tape.toTapeString


encode : (sym -> E.Value) -> KeyedTape {} sym -> E.Value
encode encodeSymbol tape =
    Tape.encode encodeSymbol
        { left = tape.left
        , right = tape.right
        , currentSymbol = tape.currentSymbol
        , emptySymbol = tape.emptySymbol
        }


decoder : D.Decoder sym -> D.Decoder (KeyedTape {} sym)
decoder symbolDecoder =
    Tape.decoder symbolDecoder
        |> D.map fromTape
