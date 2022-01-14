module App.ComputationWorkflow.Impl exposing (..)

import App.ComputationWorkflow.Step exposing (..)
import App.ComputationWorkflow.Type exposing (..)
import App.Model as Model exposing (..)
import App.Msg exposing (..)
import Core.KeyedTape as KeyedTape
import Core.Turing as Turing
import Delay
import Task
import Time


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
                            | pendingTuring =
                                Turing.applyRule currentlyApplicableRule model.turing
                                    |> Maybe.map (\turing -> { turing | tape = KeyedTape.lookahead turing.tape })
                            , pendingRuleIndex = currentlyApplicableRuleIndex
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
                ( Model.invalidateEditFields
                    { model
                        | activeComputationWorkflow = workflow
                        , turing = newTuring
                        , pendingTuring = Nothing
                        , prevTurings = model.turing :: model.prevTurings
                        , lastAppliedRuleIndex = model.pendingRuleIndex
                        , prevAppliedRuleIndexes = model.lastAppliedRuleIndex :: model.prevAppliedRuleIndexes
                        , isInitialState = False
                    }
                , cmd
                )

            _ ->
                ( model, Cmd.none )
