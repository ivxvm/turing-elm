module App.View exposing (..)

import App.ComputationWorkflow.Step exposing (..)
import App.Model exposing (..)
import App.Msg exposing (..)
import Array
import Core.KeyedTape as KeyedTape exposing (..)
import Core.Turing as Turing exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import Html.Styled.Keyed as Keyed
import List.Extra as List
import Maybe.Extra as Maybe
import Utils.AttributeExtra exposing (..)


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


tapeCellHtml : String -> String -> Bool -> Bool -> Bool -> Html Msg
tapeCellHtml key symbol isCurrent isFadingOut isFadingIn =
    div
        [ class "tape-cell"
        , class "centered"
        , classIf isCurrent "current"
        , classIf isFadingOut "fadeout"
        , classIf isFadingIn "fadein"
        , attribute "key" key
        ]
        [ text symbol ]


stateAndTapeHtml : Model -> Html Msg
stateAndTapeHtml model =
    let
        tapeSymbols =
            KeyedTape.toSymbolList model.turing.tape

        tapeKeys =
            KeyedTape.toKeyList model.turing.tape
                |> List.map String.fromInt

        currentSymbolIndex =
            KeyedTape.currentSymbolIndex model.turing.tape

        isFadeoutState =
            model.activeComputationWorkflow.step == Just OldSymbolFadeout

        isFadeinState =
            model.activeComputationWorkflow.step == Just NewSymbolFadein

        pendingRule =
            List.getAt model.pendingRuleIndex model.turing.rules

        renderedState =
            if isFadeinState then
                Maybe.unwrap model.turing.currentState (\r -> r.newState) pendingRule

            else
                model.turing.currentState

        tapePadding =
            8

        renderPaddingCell prefix i =
            ( prefix ++ String.fromInt i
            , tapeCellHtml (prefix ++ String.fromInt i) model.turing.tape.emptySymbol False False False
            )

        leftPaddingList =
            List.initialize tapePadding (renderPaddingCell "lp_")

        rightPaddingList =
            List.initialize tapePadding (renderPaddingCell "rp_")

        tapeCells =
            tapeSymbols
                |> List.indexedMap
                    (\index symbol ->
                        let
                            isCurrent =
                                index == currentSymbolIndex

                            renderedSymbol =
                                if isCurrent && isFadeinState then
                                    Maybe.unwrap "?" (\r -> r.newSymbol) pendingRule

                                else
                                    symbol
                        in
                        tapeCellHtml (Maybe.withDefault "?" (List.getAt index tapeKeys))
                            renderedSymbol
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
            , classIf model.isEditingStateAndTape "editing-toggled"
            , onClick ToggleEditStateTape
            ]
            [ text renderedState ]
        , div
            [ class "tape-wrapper" ]
            [ Keyed.node "div"
                [ class "tape" ]
                (List.concat
                    [ leftPaddingList
                    , List.zip tapeKeys tapeCells
                    , rightPaddingList
                    ]
                )
            ]
        ]


editStateAndTapeHtml : Model -> Html Msg
editStateAndTapeHtml model =
    div
        [ class "edit-state-and-tape-container"
        , classIf (not model.isEditingStateAndTape) "disabled"
        ]
        [ input
            [ placeholder "State"
            , value model.currentStateString
            , class "current-state-input"
            , classIf (Maybe.isJust model.currentStateValidationError) "invalid"
            , onInput UpdateState
            ]
            []
        , span
            [ attribute "error" (Maybe.withDefault "" model.currentStateValidationError) ]
            []
        , input
            [ placeholder "∅"
            , value model.currentEmptySymbolString
            , class "current-empty-symbol-input"
            , classIf (Maybe.isJust model.currentEmptySymbolValidationError) "invalid"
            , onInput UpdateEmptySymbol
            ]
            []
        , span
            [ attribute "error" (Maybe.withDefault "" model.currentEmptySymbolValidationError) ]
            []
        , input
            [ placeholder "Tape"
            , value model.currentTapeString
            , class "current-tape-input"
            , classIf (Maybe.isJust model.currentTapeValidationError) "invalid"
            , onInput UpdateTape
            ]
            []
        , span
            [ attribute "error" (Maybe.withDefault "" model.currentTapeValidationError) ]
            []
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
        , editStateAndTapeHtml model
        , controlsHtml model
        , rulesListHtml model
        ]
