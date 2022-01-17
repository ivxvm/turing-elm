module KeyedTapeTests exposing (..)

import Core.KeyedTape as KeyedTape exposing (..)
import Core.Tape as Tape exposing (..)
import Expect
import Json.Decode as D exposing (decodeString)
import Json.Encode as E
import List.Extra as List
import Result.Extra as Result
import TapeTests
import Test exposing (..)


exampleTape : KeyedTape {} String
exampleTape =
    KeyedTape.fromTape TapeTests.exampleTape


shiftsTest : Test
shiftsTest =
    TapeTests.testShifts "KeyedTape" exampleTape


keysTest =
    test "keys are unique" <|
        \_ ->
            KeyedTape.toKeyList exampleTape
                |> List.allDifferent
                |> Expect.true "Expected tape keys to be unique"


jsonTest : Test
jsonTest =
    describe "KeyedTape json"
        [ test "KeyedTape.encode >> KeyedTape.decode = (Tape.encode >> Tape.decode) >> KeyedTape.fromTape" <|
            \_ ->
                let
                    lhs =
                        decodeString
                            (KeyedTape.decoder D.string)
                            (E.encode 0 (KeyedTape.encode E.string exampleTape))

                    rhs =
                        Result.map KeyedTape.fromTape <|
                            decodeString
                                (Tape.decoder D.string)
                                (E.encode 0 (Tape.encode E.string TapeTests.exampleTape))
                in
                Expect.equal lhs rhs
        ]
