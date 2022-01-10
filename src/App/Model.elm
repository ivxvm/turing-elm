module App.Model exposing (..)

import App.ComputationWorkflow.Types exposing (..)
import Array exposing (Array)
import Core.Rule exposing (..)
import Core.Turing exposing (..)


type alias Model =
    { ruleStrings : List String
    , ruleValidationErrors : Array (Maybe String)
    , turing : Turing String String
    , pendingTuring : Maybe (Turing String String)
    , prevTurings : List (Turing String String)
    , lastAppliedRuleIndex : Int
    , prevAppliedRuleIndexes : List Int
    , activeComputationWorkflow : ComputationWorkflow
    , isRunning : Bool
    , isInitialState : Bool
    }
