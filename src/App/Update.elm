module App.Update exposing (..)

import App.ComputationWorkflow.Impl as ComputationWorkflow exposing (..)
import App.ComputationWorkflow.Step exposing (..)
import App.ComputationWorkflow.Type exposing (..)
import App.Model as Model exposing (..)
import App.Msg exposing (..)
import App.Ports exposing (..)
import App.Turing.BusyBeaver as BusyBeaver
import Array
import Array.Extra as Array
import Core.Direction exposing (Direction(..))
import Core.Tape as Tape exposing (..)
import Core.Turing as Turing exposing (..)
import Css exposing (..)
import Delay exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import List
import List.Extra as List
import Maybe.Extra as Maybe
import Result.Extra as Result
import Utils.AttributeExtra exposing (..)
import Utils.ListExtra as List


type alias Update =
    Msg -> Model -> ( Model, Cmd Msg )


update : Update
update msg model =
    case msg of
        AddRule ->
            ( { model
                | ruleStrings = model.ruleStrings ++ [ "" ]
                , ruleValidationErrors = Array.push Nothing model.ruleValidationErrors
              }
            , Cmd.none
            )

        RemoveRule index ->
            ( { model
                | ruleStrings = List.removeAt index model.ruleStrings
                , ruleValidationErrors = Array.removeAt index model.ruleValidationErrors
              }
            , Cmd.none
            )

        UpdateRule index newValue ->
            ( { model
                | ruleStrings = List.setAt index newValue model.ruleStrings
              }
            , Cmd.none
            )

        UpdateState newValue ->
            let
                sanitizedValue =
                    String.trim newValue

                validationError =
                    Model.validateStateString sanitizedValue

                turing =
                    model.turing
            in
            ( { model
                | currentStateString = newValue
                , currentStateValidationError = validationError
                , turing = Maybe.unwrap { turing | currentState = sanitizedValue } (\_ -> turing) validationError
              }
            , Cmd.none
            )

        UpdateEmptySymbol newValue ->
            let
                sanitizedValue =
                    String.trim newValue

                validationError =
                    Model.validateEmptySymbolString sanitizedValue
            in
            ( { model
                | currentEmptySymbolString = newValue
                , currentEmptySymbolValidationError = validationError
                , turing =
                    Maybe.unpack
                        (\() ->
                            sanitizedValue
                                |> asEmptySymbolIn model.turing.tape
                                |> asTapeIn model.turing
                        )
                        (\_ -> model.turing)
                        validationError
              }
            , Cmd.none
            )

        UpdateTape newValue ->
            let
                sanitizedValue =
                    String.trim newValue

                validationError =
                    Model.validateTapeString sanitizedValue

                newTape =
                    if Maybe.isNothing validationError then
                        Tape.fromString Just model.turing.tape.emptySymbol sanitizedValue

                    else
                        Err "Validation error"
            in
            ( { model
                | currentTapeString = newValue
                , currentTapeValidationError = Maybe.or validationError (Result.error newTape)
                , turing =
                    newTape
                        |> Result.withDefault model.turing.tape
                        |> asTapeIn model.turing
              }
            , Cmd.none
            )

        ToggleEditStateTape ->
            ( { model | isEditingStateAndTape = not model.isEditingStateAndTape }
            , Cmd.none
            )

        ToggleComputation ->
            let
                newComputationWorkflow =
                    if model.isRunning then
                        ComputationWorkflow.reset model.activeComputationWorkflow

                    else
                        model.activeComputationWorkflow

                cmd =
                    if model.isRunning then
                        Cmd.none

                    else
                        ComputationWorkflow.start newComputationWorkflow
            in
            ( { model
                | isRunning = not model.isRunning
                , pendingTuring = Nothing
                , activeComputationWorkflow = newComputationWorkflow
              }
            , cmd
            )

        ResetComputation ->
            let
                ( newComputationWorkflow, cmd ) =
                    restartComputationIfRunning model
            in
            ( Model.invalidateEditFields
                { model
                    | turing = BusyBeaver.turing
                    , pendingTuring = Nothing
                    , prevTurings = []
                    , lastAppliedRuleIndex = -1
                    , pendingRuleIndex = -1
                    , prevAppliedRuleIndexes = []
                    , activeComputationWorkflow = newComputationWorkflow
                    , isInitialState = True
                }
            , Cmd.batch [ cmd, centerCurrentTapeCell () ]
            )

        ProcessComputationWorkflow workflow ->
            ComputationWorkflow.update workflow model

        StepFw ->
            case Turing.findApplicableRule model.turing of
                Just ( currentlyApplicableRuleIndex, currentlyApplicableRule ) ->
                    let
                        ( newComputationWorkflow, cmd ) =
                            restartComputationIfRunning model

                        newTuring =
                            Turing.applyRule currentlyApplicableRule model.turing
                                |> Maybe.withDefault model.turing
                    in
                    ( Model.invalidateEditFields
                        { model
                            | turing = newTuring
                            , pendingTuring = Nothing
                            , prevTurings = model.turing :: model.prevTurings
                            , lastAppliedRuleIndex = currentlyApplicableRuleIndex
                            , pendingRuleIndex = -1
                            , prevAppliedRuleIndexes = model.lastAppliedRuleIndex :: model.prevAppliedRuleIndexes
                            , activeComputationWorkflow = newComputationWorkflow
                            , isInitialState = False
                        }
                    , Cmd.batch [ cmd, centerCurrentTapeCell () ]
                    )

                Nothing ->
                    ( model, Cmd.none )

        StepBw ->
            let
                ( newComputationWorkflow, cmd ) =
                    restartComputationIfRunning model
            in
            case ( model.prevTurings, model.prevAppliedRuleIndexes ) of
                ( prevTuring :: restPrevTurings, prevRuleIndex :: restPrevRuleIndexes ) ->
                    ( Model.invalidateEditFields
                        { model
                            | turing = prevTuring
                            , pendingTuring = Nothing
                            , prevTurings = restPrevTurings
                            , lastAppliedRuleIndex = prevRuleIndex
                            , pendingRuleIndex = -1
                            , prevAppliedRuleIndexes = restPrevRuleIndexes
                            , activeComputationWorkflow = newComputationWorkflow
                            , isInitialState = List.isEmpty restPrevTurings
                        }
                    , Cmd.batch [ cmd, centerCurrentTapeCell () ]
                    )

                _ ->
                    ( model, Cmd.none )


restartComputationIfRunning : Model -> ( ComputationWorkflow, Cmd Msg )
restartComputationIfRunning model =
    let
        newComputationWorkflow =
            if model.isRunning then
                ComputationWorkflow.reset model.activeComputationWorkflow

            else
                model.activeComputationWorkflow

        cmd =
            if model.isRunning then
                ComputationWorkflow.start newComputationWorkflow

            else
                Cmd.none
    in
    ( newComputationWorkflow, cmd )
