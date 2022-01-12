module App.Msg exposing (..)

import App.ComputationWorkflow.Type exposing (..)
import App.Model exposing (..)


type Msg
    = AddRule
    | RemoveRule Int
    | UpdateRule Int String
    | UpdateState String
    | UpdateEmptySymbol String
    | UpdateTape String
    | ToggleEditStateTape
    | ToggleComputation
    | ResetComputation
    | ProcessComputationWorkflow ComputationWorkflow
    | StepFw
    | StepBw
