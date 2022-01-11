module Main exposing (..)

import App.ComputationWorkflow.Impl as ComputationWorkflow exposing (..)
import App.ComputationWorkflow.Step exposing (..)
import App.ComputationWorkflow.Type exposing (..)
import App.Model exposing (..)
import App.Msg exposing (..)
import Array
import Array.Extra as Array
import Browser
import Core.Direction exposing (Direction(..))
import Core.Rule exposing (..)
import Core.Tape
import Core.Turing as Turing exposing (Turing)
import Css exposing (..)
import Delay exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import List
import List.Extra as List
import Maybe.Extra as Maybe
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
      , lastAppliedRuleIndex = -1
      , pendingRuleIndex = -1
      , prevAppliedRuleIndexes = []
      , activeComputationWorkflow = ComputationWorkflow.init
      , isRunning = False
      , isInitialState = True
      }
    , Cmd.none
    )


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
            ( { model
                | turing = busyBeaver
                , pendingTuring = Nothing
                , prevTurings = []
                , lastAppliedRuleIndex = -1
                , pendingRuleIndex = -1
                , prevAppliedRuleIndexes = []
                , activeComputationWorkflow = newComputationWorkflow
                , isInitialState = True
              }
            , cmd
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
                    ( { model
                        | turing = newTuring
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
                    ( { model
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


rulesListEntryHtml : Model -> Int -> String -> Html Msg
rulesListEntryHtml model ruleIndex ruleString =
    let
        validationError =
            Maybe.join (Array.get ruleIndex model.ruleValidationErrors)

        validationClass =
            Maybe.unwrap "valid" (\_ -> "invalid") validationError

        highlightedRuleIndex =
            if model.isRunning then
                model.pendingRuleIndex

            else
                model.lastAppliedRuleIndex
    in
    div
        [ class "rules-list-row"
        , class validationClass
        ]
        [ input
            [ placeholder "Rule description"
            , value ruleString
            , class "rule-input"
            , classIf (ruleIndex == highlightedRuleIndex) "highlighted-rule"
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
            model.activeComputationWorkflow.step == Just OldSymbolFadeout

        isFadeinState =
            model.activeComputationWorkflow.step == Just NewSymbolFadein

        lastAppliedRule =
            List.getAt model.lastAppliedRuleIndex model.turing.rules

        renderedState =
            if isFadeinState then
                Maybe.unwrap model.turing.currentState (\r -> r.newState) lastAppliedRule

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
                                    Maybe.unwrap symbol (\r -> r.newSymbol) lastAppliedRule

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
            Turing.isHalted model.turing
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
