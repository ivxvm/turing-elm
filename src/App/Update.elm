module App.Update exposing (..)

import App.ComputationWorkflow.Impl as ComputationWorkflow exposing (..)
import App.ComputationWorkflow.Type exposing (..)
import App.Model as Model exposing (..)
import App.Msg exposing (..)
import App.Ports as Ports
import Core.KeyedTape as KeyedTape exposing (..)
import Core.Rule as Rule exposing (..)
import Core.Turing as Turing exposing (..)
import Delay
import Dict as Dict exposing (..)
import Json.Decode as D
import List.Extra as List
import Maybe.Extra as Maybe
import Result.Extra as Result


type alias Update =
    Msg -> Model -> ( Model, Cmd Msg )


update : Update
update msg model =
    case msg of
        AddRule ->
            ( { model
                | ruleStrings = model.ruleStrings ++ [ "" ]
                , ruleValidationErrors = model.ruleValidationErrors ++ [ Nothing ]
              }
            , Cmd.none
            )

        RemoveRule index ->
            ( { model
                | ruleStrings = List.removeAt index model.ruleStrings
                , ruleValidationErrors = List.removeAt index model.ruleValidationErrors
                , turing =
                    List.removeAt index model.turing.rules
                        |> asRulesIn model.turing
              }
            , Cmd.none
            )

        UpdateRule index newValue ->
            let
                newRuleStrings =
                    List.setAt index newValue model.ruleStrings

                newRuleParses =
                    List.map (Rule.fromString identity identity) newRuleStrings

                newRuleValidationErrors =
                    List.map Result.error newRuleParses

                newRules =
                    List.filterMap Result.toMaybe newRuleParses
            in
            ( { model
                | ruleStrings = newRuleStrings
                , ruleValidationErrors = newRuleValidationErrors
                , turing = Turing.setRules newRules model.turing
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

        UpdateFinalState newValue ->
            let
                sanitizedValue =
                    String.trim newValue

                validationError =
                    Model.validateFinalStateString sanitizedValue

                turing =
                    model.turing
            in
            ( { model
                | currentFinalStateString = newValue
                , currentFinalStateValidationError = validationError
                , turing =
                    Maybe.unpack
                        (\() -> { turing | finalState = sanitizedValue })
                        (\_ -> turing)
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
                        KeyedTape.fromString Just model.turing.tape.emptySymbol sanitizedValue

                    else
                        Err "Validation error"
            in
            ( { model
                | currentTapeString = newValue
                , currentTapeValidationError = Maybe.or validationError (Result.error newTape)
                , turing =
                    newTape
                        |> Result.map KeyedTape.lookahead
                        |> Result.withDefault model.turing.tape
                        |> asTapeIn model.turing
              }
            , Cmd.none
            )

        UpdateMachineName newValue ->
            let
                sanitizedValue =
                    String.trim newValue

                validationError =
                    Model.validateMachineName sanitizedValue
            in
            ( { model
                | machineName = newValue
                , machineNameValidationError = validationError
              }
            , Cmd.none
            )

        ToggleEditConfiguration ->
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
                ( newComputationWorkflow, restartCmd ) =
                    restartComputationIfRunning model

                newTuring =
                    List.last model.prevTurings
                        |> Maybe.withDefault model.turing

                ( initialModel, initCmd ) =
                    Model.init model.machineName newTuring
            in
            ( Model.invalidateEditFields
                { initialModel
                    | savedMachines = model.savedMachines
                    , activeComputationWorkflow = newComputationWorkflow
                    , isEditingStateAndTape = model.isEditingStateAndTape
                    , isRunning = model.isRunning
                }
            , Cmd.batch [ restartCmd, initCmd ]
            )

        ProcessComputationWorkflow workflow ->
            ComputationWorkflow.update workflow model

        StepFw ->
            let
                ( newComputationWorkflow, cmd ) =
                    restartComputationIfRunning model

                step stepsLeft steppedModel =
                    if stepsLeft == 0 then
                        steppedModel

                    else
                        case Turing.findApplicableRule steppedModel.turing of
                            Just ( currentlyApplicableRuleIndex, currentlyApplicableRule ) ->
                                let
                                    newTuring =
                                        Turing.applyRule currentlyApplicableRule steppedModel.turing
                                            |> Maybe.withDefault steppedModel.turing
                                in
                                step (stepsLeft - 1)
                                    { steppedModel
                                        | turing = { newTuring | tape = KeyedTape.lookahead newTuring.tape }
                                        , prevTurings = steppedModel.turing :: steppedModel.prevTurings
                                        , lastAppliedRuleIndex = currentlyApplicableRuleIndex
                                        , prevAppliedRuleIndexes = steppedModel.lastAppliedRuleIndex :: steppedModel.prevAppliedRuleIndexes
                                    }

                            Nothing ->
                                steppedModel

                stepsToPerform =
                    Model.calculateStepsFromModifiers model

                newModel =
                    step stepsToPerform model
            in
            ( Model.invalidateEditFields
                { newModel
                    | pendingTuring = Nothing
                    , pendingRuleIndex = -1
                    , isInitialState = False
                    , activeComputationWorkflow = newComputationWorkflow
                }
            , cmd
            )

        StepBw ->
            let
                ( newComputationWorkflow, cmd ) =
                    restartComputationIfRunning model

                step stepsLeft steppedModel =
                    if stepsLeft == 0 then
                        steppedModel

                    else
                        case ( steppedModel.prevTurings, steppedModel.prevAppliedRuleIndexes ) of
                            ( prevTuring :: restPrevTurings, prevRuleIndex :: restPrevRuleIndexes ) ->
                                step (stepsLeft - 1)
                                    { steppedModel
                                        | turing = prevTuring
                                        , prevTurings = restPrevTurings
                                        , lastAppliedRuleIndex = prevRuleIndex
                                        , prevAppliedRuleIndexes = restPrevRuleIndexes
                                        , activeComputationWorkflow = newComputationWorkflow
                                        , isInitialState = List.isEmpty restPrevTurings
                                    }

                            _ ->
                                steppedModel

                stepsToPerform =
                    Model.calculateStepsFromModifiers model

                newModel =
                    step stepsToPerform model
            in
            ( Model.invalidateEditFields
                { newModel
                    | pendingTuring = Nothing
                    , pendingRuleIndex = -1
                }
            , cmd
            )

        SaveMachine ->
            ( model
            , Cmd.batch
                [ Ports.saveMachine ( model.machineName, Turing.encodeSimple model.turing )
                , Delay.after 250 GetSavedMachines
                ]
            )

        LoadMachine name ->
            let
                newTuring =
                    Dict.get name model.savedMachines
                        |> Maybe.withDefault model.turing

                ( newModel, initCmd ) =
                    Model.init name newTuring
            in
            ( Model.invalidateEditFields
                { newModel
                    | savedMachines = model.savedMachines
                    , activeComputationWorkflow = ComputationWorkflow.reset model.activeComputationWorkflow
                    , isEditingStateAndTape = model.isEditingStateAndTape
                    , isRunning = False
                }
            , initCmd
            )

        DeleteMachine name ->
            ( { model | savedMachines = Dict.remove name model.savedMachines }
            , Cmd.none
            )

        GetSavedMachines ->
            ( model
            , Ports.getSavedMachines ()
            )

        GetSavedMachinesSuccess payload ->
            ( { model
                | savedMachines =
                    payload
                        |> List.map (Result.combineMapSecond (D.decodeString Turing.decoderSimple))
                        |> Result.partition
                        |> Tuple.first
                        |> Dict.fromList
              }
            , Cmd.none
            )

        KeyDown key ->
            case key of
                "Meta" ->
                    ( { model | isMinorStepSpeedupOn = True }, Cmd.none )

                "Control" ->
                    ( { model | isMinorStepSpeedupOn = True }, Cmd.none )

                "Shift" ->
                    ( { model | isMajorStepSpeedupOn = True }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        KeyUp key ->
            case key of
                "Meta" ->
                    ( { model | isMinorStepSpeedupOn = False }, Cmd.none )

                "Control" ->
                    ( { model | isMinorStepSpeedupOn = False }, Cmd.none )

                "Shift" ->
                    ( { model | isMajorStepSpeedupOn = False }, Cmd.none )

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
