module App.ComputationWorkflow.Step exposing (..)


type Step
    = ComputeNextState
    | OldSymbolFadeout
    | NewSymbolFadein
    | UpdateMachineState
