module TapeTests exposing (..)

import Core.Direction as Direction exposing (..)
import Core.Tape as Tape exposing (..)
import Expect
import Json.Decode as D exposing (decodeString)
import Json.Encode as E
import Result.Extra as Result
import Test exposing (..)


testShifts : String -> Tape ext String -> Test
testShifts tapeType tape =
    let
        shiftedLeft =
            Tape.shift Direction.Left tape

        shiftedRight =
            Tape.shift Direction.Right tape
    in
    describe (tapeType ++ " shifts")
        [ test "shiftedLeft.left" <| \_ -> Expect.equal [] shiftedLeft.left
        , test "shiftedLeft.right" <| \_ -> Expect.equal [ "b", "c" ] shiftedLeft.right
        , test "shiftedLeft.currentSymbol" <| \_ -> Expect.equal "a" shiftedLeft.currentSymbol
        , test "shiftedLeft.emptySymbol" <| \_ -> Expect.equal tape.emptySymbol shiftedLeft.emptySymbol
        , test "shiftedRight.left" <| \_ -> Expect.equal (List.reverse [ "a", "b" ]) shiftedRight.left
        , test "shiftedRight.right" <| \_ -> Expect.equal [] shiftedRight.right
        , test "shiftedRight.currentSymbol" <| \_ -> Expect.equal "c" shiftedRight.currentSymbol
        , test "shiftedRight.emptySymbol" <| \_ -> Expect.equal tape.emptySymbol shiftedRight.emptySymbol
        , test "shiftLeft >> shiftRight = identity" <|
            \_ ->
                Expect.equal tape
                    (tape
                        |> Tape.shift Direction.Left
                        |> Tape.shift Direction.Right
                    )
        ]


exampleTape : Tape {} String
exampleTape =
    Tape.fromString Just "_" "a [b] c"
        |> Result.unpack (\e -> Debug.todo ("Fix test tape string: " ++ e)) identity


shiftsTest : Test
shiftsTest =
    testShifts "Tape" exampleTape


jsonTest : Test
jsonTest =
    describe "Tape json"
        [ test "encode >> decode = identity" <|
            \_ ->
                Expect.equal
                    (Result.Ok exampleTape)
                    (decodeString
                        (Tape.decoder D.string)
                        (E.encode 0 (Tape.encode E.string exampleTape))
                    )
        ]
