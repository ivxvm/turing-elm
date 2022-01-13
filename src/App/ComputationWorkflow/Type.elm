module App.ComputationWorkflow.Type exposing (..)

import App.ComputationWorkflow.Step exposing (..)


type alias ComputationWorkflow =
    { id : Int
    , step : Maybe Step
    }


init : ComputationWorkflow
init =
    { id = 0, step = Nothing }
