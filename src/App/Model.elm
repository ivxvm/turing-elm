module App.Model exposing (..)

import App.ComputationWorkflow.Type exposing (..)
import Array exposing (Array)
import Core.Rule exposing (..)
import Core.Tape as Tape
import Core.Turing exposing (..)


type alias Model =
    { ruleStrings : List String
    , ruleValidationErrors : Array (Maybe String)
    , currentStateString : String
    , currentStateValidationError : Maybe String
    , currentEmptySymbolString : String
    , currentEmptySymbolValidationError : Maybe String
    , currentTapeString : String
    , currentTapeValidationError : Maybe String
    , turing : Turing String String
    , pendingTuring : Maybe (Turing String String)
    , prevTurings : List (Turing String String)
    , lastAppliedRuleIndex : Int
    , pendingRuleIndex : Int
    , prevAppliedRuleIndexes : List Int
    , activeComputationWorkflow : ComputationWorkflow
    , isRunning : Bool
    , isInitialState : Bool
    , isEditingStateAndTape : Bool
    }


validateStateString : String -> Maybe String
validateStateString stateString =
    if String.isEmpty stateString then
        Just "State unspecified"

    else
        Nothing


validateEmptySymbolString : String -> Maybe String
validateEmptySymbolString emptySymbol =
    if String.isEmpty emptySymbol then
        Just "Empty symbol unspecified"

    else
        Nothing


validateTapeString : String -> Maybe String
validateTapeString tapeString =
    if String.isEmpty tapeString then
        Just "Tape unspecified"

    else
        Nothing


invalidateEditFields : Model -> Model
invalidateEditFields model =
    { model
        | currentStateString = model.turing.currentState
        , currentStateValidationError = Nothing
        , currentEmptySymbolString = model.turing.tape.emptySymbol
        , currentEmptySymbolValidationError = Nothing
        , currentTapeString = Tape.toTapeString identity model.turing.tape
        , currentTapeValidationError = Nothing
    }
