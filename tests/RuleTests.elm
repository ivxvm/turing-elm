module RuleTests exposing (..)

import Core.Direction as Direction exposing (..)
import Core.Rule as Rule exposing (..)
import Expect
import Json.Decode as D exposing (decodeString)
import Json.Encode as E
import Test exposing (..)


testRule : Rule String String
testRule =
    { currentState = "A"
    , currentSymbol = "0"
    , newSymbol = "1"
    , newState = "B"
    , moveDirection = Direction.Right
    }


testRuleStringFormArbitrary : String
testRuleStringFormArbitrary =
    "    A   0 1   B  R   "


testRuleStringFormSanitized : String
testRuleStringFormSanitized =
    "A 0 1 B R"


ruleFromString : Test
ruleFromString =
    test "Rule.fromString" <|
        \_ ->
            Expect.equal
                (Just testRule)
                (Rule.fromString identity identity testRuleStringFormArbitrary)


ruleToString : Test
ruleToString =
    test "Rule.toString" <|
        \_ ->
            Expect.equal
                testRuleStringFormSanitized
                (Rule.toString identity identity testRule)


ruleEncodeDecode : Test
ruleEncodeDecode =
    test "encode >> decode = identity" <|
        \_ ->
            Expect.equal
                (Result.Ok testRule)
                (decodeString
                    (Rule.decoder D.string D.string)
                    (E.encode 0 (Rule.encode E.string E.string testRule))
                )
