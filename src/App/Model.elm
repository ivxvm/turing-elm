module App.Model exposing (..)

import App.ComputationWorkflow.Type as ComputationWorkflow exposing (..)
import App.Ports as Ports
import Core.KeyedTape as KeyedTape exposing (..)
import Core.Rule as Rule exposing (..)
import Core.Turing exposing (..)
import Dict as Dict exposing (..)


type alias Model =
    { machineName : String
    , machineNameValidationError : Maybe String
    , savedMachines : Dict String (Turing String String)
    , ruleStrings : List String
    , ruleValidationErrors : List (Maybe String)
    , currentStateString : String
    , currentStateValidationError : Maybe String
    , currentEmptySymbolString : String
    , currentEmptySymbolValidationError : Maybe String
    , currentFinalStateString : String
    , currentFinalStateValidationError : Maybe String
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
    , isMinorStepSpeedupOn : Bool
    , isMajorStepSpeedupOn : Bool
    }


init : String -> Turing String String -> ( Model, Cmd msg )
init name turing =
    ( invalidateEditFields
        { machineName = name
        , machineNameValidationError = Nothing
        , savedMachines = Dict.empty
        , ruleStrings =
            turing.rules
                |> List.map (Rule.toString identity identity)
        , ruleValidationErrors = List.repeat (List.length turing.rules) Nothing
        , currentStateString = ""
        , currentStateValidationError = Nothing
        , currentEmptySymbolString = ""
        , currentEmptySymbolValidationError = Nothing
        , currentFinalStateString = ""
        , currentFinalStateValidationError = Nothing
        , currentTapeString = ""
        , currentTapeValidationError = Nothing
        , turing = { turing | tape = KeyedTape.lookahead turing.tape }
        , pendingTuring = Nothing
        , prevTurings = []
        , lastAppliedRuleIndex = -1
        , pendingRuleIndex = -1
        , prevAppliedRuleIndexes = []
        , activeComputationWorkflow = ComputationWorkflow.init
        , isRunning = False
        , isInitialState = True
        , isEditingStateAndTape = False
        , isMinorStepSpeedupOn = False
        , isMajorStepSpeedupOn = False
        }
    , Ports.centerCurrentTapeCell ()
    )


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


validateFinalStateString : String -> Maybe String
validateFinalStateString emptySymbol =
    if String.isEmpty emptySymbol then
        Just "Final state unspecified"

    else
        Nothing


validateMachineName : String -> Maybe String
validateMachineName machineName =
    if String.isEmpty machineName then
        Just "Machine name shouldn't be empty"

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
        , currentFinalStateString = model.turing.finalState
        , currentFinalStateValidationError = Nothing
        , currentTapeString = KeyedTape.toTapeString identity model.turing.tape
        , currentTapeValidationError = Nothing
    }


calculateStepsFromModifiers : Model -> Int
calculateStepsFromModifiers model =
    case ( model.isMinorStepSpeedupOn, model.isMajorStepSpeedupOn ) of
        ( _, True ) ->
            100

        ( True, _ ) ->
            10

        _ ->
            1
