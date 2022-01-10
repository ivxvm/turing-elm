module App.ComputationWorkflow.Types exposing (..)


type ComputationWorkflowStep
    = ComputeNextState
    | OldSymbolFadeout
    | NewSymbolFadein
    | UpdateMachineState


type alias ComputationWorkflow =
    { id : Int
    , step : Maybe ComputationWorkflowStep
    }
