module Model exposing (..)

import Array exposing (Array)
import Core.Rule exposing (Rule)
import Core.Turing exposing (Turing)


type AnimatedComputationStepState
    = ComputeNextState
    | OldSymbolFadeout
    | NewSymbolFadein
    | UpdateMachineState


type alias Model =
    { ruleStrings : List String
    , ruleValidationErrors : Array (Maybe String)
    , turing : Turing String String
    , pendingTuring : Maybe (Turing String String)
    , prevTurings : List (Turing String String)
    , lastAppliedRule : Maybe (Rule String String)
    , lastAppliedRuleIndex : Maybe Int
    , computationThreadId : Int
    , animatedComputationStepState : Maybe AnimatedComputationStepState
    , isRunning : Bool
    , isInitialState : Bool
    }
