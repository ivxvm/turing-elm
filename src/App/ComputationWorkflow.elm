module App.ComputationWorkflow exposing (..)

import App.ComputationWorkflow.Types exposing (ComputationWorkflow, ComputationWorkflowStep(..))
import App.Model exposing (..)
import App.Msg exposing (..)
import Core.Turing as Turing
import Delay
import Maybe.Extra as Maybe
import Task
import Time


init : ComputationWorkflow
init =
    { id = 0, step = Nothing }


reset : ComputationWorkflow -> ComputationWorkflow
reset workflow =
    { id = workflow.id + 1, step = Nothing }


start : ComputationWorkflow -> Cmd Msg
start workflow =
    Task.perform
        (\_ ->
            ProcessComputationWorkflow
                { workflow
                    | step = Just (Maybe.withDefault ComputeNextState workflow.step)
                }
        )
        Time.now


update : ComputationWorkflow -> Model -> ( Model, Cmd Msg )
update workflow model =
    if workflow.id /= model.activeComputationWorkflow.id then
        ( model, Cmd.none )

    else
        case workflow.step of
            Just ComputeNextState ->
                case Turing.findApplicableRule model.turing of
                    Just ( currentlyApplicableRuleIndex, currentlyApplicableRule ) ->
                        ( { model
                            | pendingTuring = Turing.applyRule currentlyApplicableRule model.turing
                            , lastAppliedRuleIndex = currentlyApplicableRuleIndex
                            , prevAppliedRuleIndexes = model.lastAppliedRuleIndex :: model.prevAppliedRuleIndexes
                            , activeComputationWorkflow = workflow
                          }
                        , Delay.after 250 (ProcessComputationWorkflow { workflow | step = Just OldSymbolFadeout })
                        )

                    Nothing ->
                        ( model, Task.perform (\_ -> ToggleComputation) Time.now )

            Just OldSymbolFadeout ->
                ( { model | activeComputationWorkflow = workflow }
                , Delay.after 1000 (ProcessComputationWorkflow { workflow | step = Just NewSymbolFadein })
                )

            Just NewSymbolFadein ->
                ( { model | activeComputationWorkflow = workflow }
                , Delay.after 1000 (ProcessComputationWorkflow { workflow | step = Just UpdateMachineState })
                )

            Just UpdateMachineState ->
                let
                    newTuring =
                        Maybe.withDefault model.turing model.pendingTuring

                    cmd =
                        if Turing.isHalted newTuring then
                            Delay.after 0 ToggleComputation

                        else
                            Delay.after 250 (ProcessComputationWorkflow { workflow | step = Just ComputeNextState })
                in
                ( { model
                    | activeComputationWorkflow = workflow
                    , turing = newTuring
                    , pendingTuring = Nothing
                    , prevTurings = model.turing :: model.prevTurings
                    , isInitialState = False
                  }
                , cmd
                )

            _ ->
                ( model, Cmd.none )
