module App.Msg exposing (..)

import App.ComputationWorkflow.Types exposing (..)
import App.Model exposing (..)


type Msg
    = AddRule
    | RemoveRule Int
    | UpdateRule Int String
    | ToggleComputation
    | ResetComputation
    | ProcessComputationWorkflow ComputationWorkflow
    | StepFw
    | StepBw
