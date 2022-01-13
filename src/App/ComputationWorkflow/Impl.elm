module App.ComputationWorkflow.Impl exposing (..)

import App.ComputationWorkflow.Step exposing (..)
import App.ComputationWorkflow.Type exposing (..)
import App.Model as Model exposing (..)
import App.Msg exposing (..)
import App.Ports as Ports
import Core.Direction as Direction
import Core.Turing as Turing
import Delay
import List.Extra as List
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
                            , pendingRuleIndex = currentlyApplicableRuleIndex
                            , activeComputationWorkflow = workflow
                          }
                        , Cmd.batch
                            [ Ports.centerCurrentTapeCell ()
                            , Delay.after 250 (ProcessComputationWorkflow { workflow | step = Just OldSymbolFadeout })
                            ]
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

                    isLeftMove =
                        List.getAt model.pendingRuleIndex model.turing.rules
                            |> Maybe.map .moveDirection
                            |> Maybe.filter (\d -> d == Direction.Left)
                            |> Maybe.isJust

                    shouldOffsetTape =
                        isLeftMove && model.turing.tape.left == []
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
                , Cmd.batch
                    [ cmd
                    , if shouldOffsetTape then
                        Ports.scrollTape 50

                      else
                        Cmd.none
                    ]
                )

            _ ->
                ( model, Cmd.none )
