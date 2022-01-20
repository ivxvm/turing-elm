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
                            | turing = { newTuring | tape = KeyedTape.lookahead newTuring.tape }
                            , pendingTuring = Nothing
                            , prevTurings = model.turing :: model.prevTurings
                            , lastAppliedRuleIndex = currentlyApplicableRuleIndex
                            , pendingRuleIndex = -1
                            , prevAppliedRuleIndexes = model.lastAppliedRuleIndex :: model.prevAppliedRuleIndexes
                            , activeComputationWorkflow = newComputationWorkflow
                            , isInitialState = False
                        }
                    , cmd
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
                    , cmd
                    )

                _ ->
                    ( model, Cmd.none )

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
