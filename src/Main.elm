module Main exposing (..)

import Array exposing (Array)
import Array.Extra as Array
import Browser
import Core.Direction exposing (Direction(..))
import Core.Rule exposing (..)
import Core.Tape
import Core.Turing exposing (Turing)
import Css exposing (..)
import Delay exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import List
import List.Extra as List
import Maybe.Extra as Maybe
import Model exposing (..)
import Task
import Time
import Utils.AttributeExtra exposing (..)


busyBeaver : Turing String String
busyBeaver =
    { tape = { left = [], right = [], currentSymbol = "0", emptySymbol = "0" }
    , currentState = "A"
    , isFinalState = \s -> s == "X"
    , rules =
        [ Rule "A" "1" "1" "C" Left
        , Rule "A" "0" "1" "B" Right
        , Rule "B" "0" "1" "A" Left
        , Rule "B" "1" "1" "B" Right
        , Rule "C" "0" "1" "B" Left
        , Rule "C" "1" "1" "X" Right
        ]
    }


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view >> toUnstyled
        , subscriptions = \_ -> Sub.none
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { ruleStrings =
            busyBeaver.rules
                |> List.map (Core.Rule.toString identity identity)
      , ruleValidationErrors = Array.repeat (List.length busyBeaver.rules) Nothing
      , turing = busyBeaver
      , pendingTuring = Nothing
      , prevTurings = []
      , lastAppliedRule = Nothing
      , lastAppliedRuleIndex = Nothing
      , computationThreadId = 0
      , animatedComputationStepState = Nothing
      , isRunning = False
      , isInitialState = True
      }
    , Cmd.none
    )


type Msg
    = AddRule
    | RemoveRule Int
    | UpdateRule Int String
    | ToggleComputation
    | ResetComputation
    | AnimateComputationStep Int AnimatedComputationStepState
    | StepFw
    | StepBw


startComputationThread : Int -> Msg
startComputationThread threadId =
    AnimateComputationStep threadId ComputeNextState


update : Msg -> Model -> ( Model, Cmd Msg )
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

        ToggleComputation ->
            let
                newComputationThreadId =
                    if model.isRunning then
                        model.computationThreadId + 1

                    else
                        model.computationThreadId

                cmd =
                    if model.isRunning then
                        Cmd.none

                    else
                        Task.perform (\_ -> startComputationThread newComputationThreadId) Time.now
            in
            ( { model
                | isRunning = not model.isRunning
                , computationThreadId = newComputationThreadId
                , pendingTuring = Nothing
                , animatedComputationStepState = Nothing
              }
            , cmd
            )

        ResetComputation ->
            let
                ( newComputationThreadId, cmd ) =
                    restartComputationIfRunning model
            in
            ( { model
                | turing = busyBeaver
                , lastAppliedRule = Nothing
                , lastAppliedRuleIndex = Nothing
                , pendingTuring = Nothing
                , prevTurings = []
                , animatedComputationStepState = Nothing
                , computationThreadId = newComputationThreadId
                , isInitialState = True
              }
            , cmd
            )

        AnimateComputationStep threadId ComputeNextState ->
            whenThreadIsAlive model threadId <|
                \() ->
                    case Core.Turing.findApplicableRule model.turing of
                        Just ( currentlyApplicableRuleIndex, currentlyApplicableRule ) ->
                            let
                                nextTuring =
                                    Core.Turing.applyRule currentlyApplicableRule model.turing

                                newModel =
                                    { model
                                        | pendingTuring = nextTuring
                                        , lastAppliedRule = Just currentlyApplicableRule
                                        , lastAppliedRuleIndex = Just currentlyApplicableRuleIndex
                                        , animatedComputationStepState = Just ComputeNextState
                                    }
                            in
                            ( newModel
                            , Delay.after 250 (AnimateComputationStep threadId OldSymbolFadeout)
                            )

                        Nothing ->
                            ( model, Task.perform (\_ -> ToggleComputation) Time.now )

        AnimateComputationStep threadId OldSymbolFadeout ->
            whenThreadIsAlive model threadId <|
                \() ->
                    ( { model | animatedComputationStepState = Just OldSymbolFadeout }
                    , Delay.after 1000 (AnimateComputationStep threadId NewSymbolFadein)
                    )

        AnimateComputationStep threadId NewSymbolFadein ->
            whenThreadIsAlive model threadId <|
                \() ->
                    ( { model | animatedComputationStepState = Just NewSymbolFadein }
                    , Delay.after 1000 (AnimateComputationStep threadId UpdateMachineState)
                    )

        AnimateComputationStep threadId UpdateMachineState ->
            whenThreadIsAlive model threadId <|
                \() ->
                    let
                        newTuring =
                            Maybe.withDefault model.turing model.pendingTuring

                        cmd =
                            if Core.Turing.isHalted newTuring then
                                Delay.after 0 ToggleComputation

                            else
                                Delay.after 250 (AnimateComputationStep threadId ComputeNextState)
                    in
                    ( { model
                        | animatedComputationStepState = Just UpdateMachineState
                        , turing = newTuring
                        , pendingTuring = Nothing
                        , prevTurings = model.turing :: model.prevTurings
                        , isInitialState = False
                      }
                    , cmd
                    )

        StepFw ->
            case Core.Turing.findApplicableRule model.turing of
                Just ( currentlyApplicableRuleIndex, currentlyApplicableRule ) ->
                    let
                        ( newComputationThreadId, cmd ) =
                            restartComputationIfRunning model

                        newTuring =
                            Core.Turing.applyRule currentlyApplicableRule model.turing
                                |> Maybe.withDefault model.turing
                    in
                    ( { model
                        | turing = newTuring
                        , prevTurings = model.turing :: model.prevTurings
                        , pendingTuring = Nothing
                        , lastAppliedRule = Just currentlyApplicableRule
                        , lastAppliedRuleIndex = Just currentlyApplicableRuleIndex
                        , animatedComputationStepState = Nothing
                        , computationThreadId = newComputationThreadId
                        , isInitialState = False
                      }
                    , cmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        StepBw ->
            let
                ( newComputationThreadId, cmd ) =
                    restartComputationIfRunning model
            in
            case model.prevTurings of
                prevTuring :: restPrevTurings ->
                    ( { model
                        | computationThreadId = newComputationThreadId
                        , turing = prevTuring
                        , prevTurings = restPrevTurings
                        , pendingTuring = Nothing
                        , animatedComputationStepState = Nothing
                        , isInitialState = List.isEmpty restPrevTurings
                      }
                    , cmd
                    )

                [] ->
                    ( model, Cmd.none )


restartComputationIfRunning : Model -> ( Int, Cmd Msg )
restartComputationIfRunning model =
    let
        newComputationThreadId =
            if model.isRunning then
                model.computationThreadId + 1

            else
                model.computationThreadId

        cmd =
            if model.isRunning then
                Task.perform (\_ -> startComputationThread newComputationThreadId) Time.now

            else
                Cmd.none
    in
    ( newComputationThreadId, cmd )


whenThreadIsAlive : Model -> Int -> (() -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg )
whenThreadIsAlive model threadId fn =
    if threadId == model.computationThreadId then
        fn ()

    else
        ( model, Cmd.none )


rulesListEntryHtml : Model -> Int -> String -> Html Msg
rulesListEntryHtml model ruleIndex ruleString =
    let
        validationError =
            Maybe.join (Array.get ruleIndex model.ruleValidationErrors)

        validationClass =
            Maybe.unwrap "valid" (\_ -> "invalid") validationError
    in
    div
        [ class "rules-list-row"
        , class validationClass
        ]
        [ input
            [ placeholder "Rule description"
            , value ruleString
            , class "rule-input"
            , onInput (UpdateRule ruleIndex)
            ]
            []
        , button
            [ class "remove-rule"
            , onClick (RemoveRule ruleIndex)
            ]
            [ text "X" ]
        ]


rulesListHtml : Model -> Html Msg
rulesListHtml model =
    div
        [ class "rules-container" ]
        [ div [ class "rules-list" ] <|
            List.indexedMap (rulesListEntryHtml model) model.ruleStrings
        , div
            [ class "centered" ]
            [ button
                [ class "add-rule", onClick AddRule ]
                [ text "+" ]
            ]
        ]


tapeCellHtml : String -> Bool -> Bool -> Bool -> Html Msg
tapeCellHtml symbol isCurrent isFadingOut isFadingIn =
    div
        [ class "tape-cell"
        , class "centered"
        , classIf isCurrent "current"
        , classIf isFadingOut "fadeout"
        , classIf isFadingIn "fadein"
        ]
        [ text symbol ]


stateAndTapeHtml : Model -> Html Msg
stateAndTapeHtml model =
    let
        ( tapeSymbols, currentSymbolIndex ) =
            Core.Tape.toSymbolList 24 model.turing.tape

        isFadeoutState =
            model.animatedComputationStepState == Just OldSymbolFadeout

        isFadeinState =
            model.animatedComputationStepState == Just NewSymbolFadein

        renderedState =
            if isFadeinState then
                Maybe.unwrap model.turing.currentState (\r -> r.newState) model.lastAppliedRule

            else
                model.turing.currentState

        tapeCells =
            tapeSymbols
                |> List.indexedMap
                    (\index symbol ->
                        let
                            isCurrent =
                                index == currentSymbolIndex

                            renderedSymbol =
                                if isCurrent && isFadeinState then
                                    Maybe.unwrap symbol (\r -> r.newSymbol) model.lastAppliedRule

                                else
                                    symbol
                        in
                        tapeCellHtml renderedSymbol
                            isCurrent
                            (isCurrent && isFadeoutState)
                            (isCurrent && isFadeinState)
                    )
    in
    div
        [ class "state-and-tape-container" ]
        [ div
            [ class "state"
            , class "centered"
            , classIf isFadeoutState "fadeout"
            , classIf isFadeinState "fadein"
            ]
            [ text renderedState ]
        , div
            [ class "tape", class "centered" ]
            tapeCells
        ]


controlsHtml : Model -> Html Msg
controlsHtml model =
    let
        toggleBtnText =
            if model.isRunning then
                "stop"

            else
                "start"

        isHalted =
            Core.Turing.isHalted model.turing
    in
    div [ class "centered" ]
        [ div [ class "controls" ]
            [ div
                [ class "ctrl-step-bw"
                , classIf model.isInitialState "disabled"
                , onClickIf (not model.isInitialState) StepBw
                ]
                [ text "<<" ]
            , div
                [ class "ctrl-toggle"
                , onClick ToggleComputation
                ]
                [ text toggleBtnText ]
            , div
                [ class "ctrl-reset"
                , onClick ResetComputation
                ]
                [ text "reset" ]
            , div
                [ class "ctrl-step-fw"
                , classIf isHalted "disabled"
                , onClickIf (not isHalted) StepFw
                ]
                [ text ">>" ]
            ]
        ]


view : Model -> Html Msg
view model =
    div
        [ class "app-container" ]
        [ stateAndTapeHtml model
        , controlsHtml model
        , rulesListHtml model
        ]
