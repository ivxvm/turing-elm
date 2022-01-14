module App.UpdateScroll exposing (..)

import App.ComputationWorkflow.Step exposing (Step(..))
import App.Msg exposing (Msg(..))
import App.Ports as Ports
import App.Update exposing (Update)
import Core.Direction as Direction
import List.Extra as List
import Maybe.Extra as Maybe


isAffectingScroll : Msg -> Bool
isAffectingScroll msg =
    case msg of
        ResetComputation ->
            True

        StepFw ->
            True

        StepBw ->
            True

        ProcessComputationWorkflow workflow ->
            workflow.step == Just UpdateMachineState

        _ ->
            False


withScrollUpdate : Update -> Update
withScrollUpdate updateFn msg model =
    let
        ( newModel, cmd ) =
            updateFn msg model

        isStepBw =
            msg == StepBw

        isLeftMove =
            List.getAt newModel.lastAppliedRuleIndex newModel.turing.rules
                |> Maybe.map .moveDirection
                |> Maybe.filter (\d -> d == Direction.Left)
                |> Maybe.isJust

        shouldOffsetTape =
            isLeftMove && List.length model.turing.tape.left == 1

        tapeOffsetCells =
            if isStepBw then
                -1

            else
                1

        offsetScrollCmd =
            if shouldOffsetTape then
                Ports.scrollTape tapeOffsetCells

            else
                Cmd.none
    in
    if isAffectingScroll msg then
        ( newModel
        , Cmd.batch
            [ cmd
            , offsetScrollCmd
            , Ports.centerCurrentTapeCell ()
            ]
        )

    else
        ( newModel, cmd )
