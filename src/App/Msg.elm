module App.Msg exposing (..)

import App.ComputationWorkflow.Type exposing (..)


type Msg
    = AddRule
    | RemoveRule Int
    | UpdateRule Int String
    | UpdateState String
    | UpdateEmptySymbol String
    | UpdateFinalState String
    | UpdateTape String
    | UpdateMachineName String
    | ToggleEditConfiguration
    | ToggleComputation
    | ResetComputation
    | ProcessComputationWorkflow ComputationWorkflow
    | StepFw
    | StepBw
    | SaveMachine
    | LoadMachine String
    | DeleteMachine String
    | GetSavedMachines
    | GetSavedMachinesSuccess (List ( String, String ))
