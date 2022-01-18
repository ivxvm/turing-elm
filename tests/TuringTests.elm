module TuringTests exposing (..)

import Core.Direction as Direction exposing (..)
import Core.KeyedTape as KeyedTape exposing (..)
import Core.Rule exposing (..)
import Core.Turing as Turing exposing (..)
import Expect
import Json.Decode exposing (decodeString)
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Test exposing (..)


exampleTuring : Turing String String
exampleTuring =
    { tape =
        KeyedTape.fromTape
            { left = []
            , right = []
            , currentSymbol = "0"
            , emptySymbol = "0"
            }
    , currentState = "A"
    , finalState = "X"
    , rules =
        [ Rule "A" "0" "1" "B" Direction.Right
        , Rule "B" "0" "1" "X" Direction.Left
        ]
    }


example1Step : Maybe (Turing String String)
example1Step =
    Turing.findApplicableRule exampleTuring
        |> Maybe.andThen (\( _, rule ) -> Turing.applyRule rule exampleTuring)


example2Steps : Maybe (Turing String String)
example2Steps =
    example1Step
        |> Maybe.andThen
            (\turing ->
                Turing.findApplicableRule turing
                    |> Maybe.andThen (\( _, rule ) -> Turing.applyRule rule turing)
            )


findApplicableRuleTest : Test
findApplicableRuleTest =
    describe "Turing.findApplicableRule"
        [ test "able to find the rule" <|
            \_ ->
                Turing.findApplicableRule exampleTuring
                    |> Maybe.isJust
                    |> Expect.true "Should be able to find the rule"
        , test "returned index referencing the same rule as returned rule" <|
            \_ ->
                Turing.findApplicableRule exampleTuring
                    |> Maybe.map
                        (\( applicableRuleIndex, applicableRule ) ->
                            Just applicableRule == List.getAt applicableRuleIndex exampleTuring.rules
                        )
                    |> Expect.equal (Just True)
        ]


turingTests1Step : Test
turingTests1Step =
    describe "Example turing machine after 1 rule application"
        [ test "rule application didn't fail" <|
            \_ ->
                example1Step |> Maybe.isJust |> Expect.true ""
        , test "new state is B" <|
            \_ ->
                example1Step |> Maybe.map (\t -> t.currentState) |> Expect.equal (Just "B")
        , test "symbol on the left is changed to 1" <|
            \_ ->
                example1Step |> Maybe.map (\t -> List.head t.tape.left) |> Maybe.join |> Expect.equal (Just "1")
        ]


turingTests2Steps : Test
turingTests2Steps =
    describe "Example turing machine after 2 rule applications"
        [ test "rule application didn't fail" <|
            \_ ->
                example2Steps |> Maybe.isJust |> Expect.true ""
        , test "new state is X" <|
            \_ ->
                example2Steps |> Maybe.map (\t -> t.currentState) |> Expect.equal (Just "X")
        , test "current symbol is 1" <|
            \_ ->
                example2Steps |> Maybe.map (\t -> t.tape.currentSymbol) |> Expect.equal (Just "1")
        , test "symbol on the right is changed to 1" <|
            \_ ->
                example2Steps |> Maybe.map (\t -> List.head t.tape.right) |> Maybe.join |> Expect.equal (Just "1")
        ]


jsonTest : Test
jsonTest =
    describe "Turing json"
        [ test "encode >> decode = identity" <|
            \_ ->
                Expect.equal
                    (Result.Ok exampleTuring)
                    (decodeString
                        Turing.decoderSimple
                        (E.encode 0 (Turing.encodeSimple exampleTuring))
                    )
        ]
