module App.Msg exposing (..)

import App.ComputationWorkflow.Type exposing (..)


type Msg
    = AddRule
    | RemoveRule Int
    | UpdateRule Int String
    | UpdateState String
    | UpdateEmptySymbol String
    | UpdateTape String
    | UpdateMachineName String
    | ToggleEditConfiguration
    | ToggleComputation
    | ResetComputation
    | ProcessComputationWorkflow ComputationWorkflow
    | StepFw
    | StepBw
    | SaveMachine
    | GetSavedMachines
    | GetSavedMachinesSuccess (List ( String, String ))
