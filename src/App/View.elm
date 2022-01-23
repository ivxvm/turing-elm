module App.View exposing (..)

import App.ComputationWorkflow.Step exposing (..)
import App.Model exposing (..)
import App.Msg exposing (..)
import Core.KeyedTape as KeyedTape exposing (..)
import Core.Turing as Turing exposing (..)
import Dict
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import Html.Styled.Keyed as Keyed
import List as List
import List.Extra as List
import Maybe.Extra as Maybe
import Utils.AttributeExtra exposing (..)


rulesListEntryHtml : Model -> Int -> String -> Html Msg
rulesListEntryHtml model ruleIndex ruleString =
    let
        validationError =
            Maybe.join (List.getAt ruleIndex model.ruleValidationErrors)

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
        ]
        [ input
            [ placeholder "OldState OldSymbol NewSymbol NewState MoveDirection"
            , title (Maybe.withDefault "" validationError)
            , value ruleString
            , class "rule-input"
            , class validationClass
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
            String.slice 0 3 <|
                if isFadeinState then
                    Maybe.unwrap model.turing.currentState (\r -> r.newState) pendingRule

                else
                    model.turing.currentState

        isSingleCharState =
            String.length renderedState == 1

        isTwoCharsState =
            String.length renderedState == 2

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
            , classIf isSingleCharState "onechar"
            , classIf isTwoCharsState "twochars"
            , classIf (not isSingleCharState && not isTwoCharsState) "morechars"
            , classIf model.isEditingStateAndTape "editing-toggled"
            , onClick ToggleEditConfiguration
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


configurationHtml : Model -> Html Msg
configurationHtml model =
    div
        [ class "configuration-container" ]
        [ div
            [ class "configuration-row"
            , classIf (not model.isEditingStateAndTape) "disabled"
            ]
            [ input
                [ placeholder "Machine name"
                , title "Machine name"
                , value model.machineName
                , class "machine-name-input"
                , classIf (Maybe.isJust model.machineNameValidationError) "invalid"
                , onInput UpdateMachineName
                ]
                []
            , div
                [ class "save-machine-button"
                , onClick SaveMachine
                ]
                [ text "save" ]
            ]
        , div
            [ class "configuration-row"
            , classIf (not model.isEditingStateAndTape) "disabled"
            ]
            [ input
                [ placeholder "Tape"
                , title "Current tape"
                , value model.currentTapeString
                , class "current-tape-input"
                , classIf (Maybe.isJust model.currentTapeValidationError) "invalid"
                , onInput UpdateTape
                ]
                []
            , span
                [ attribute "error" (Maybe.withDefault "" model.currentTapeValidationError) ]
                []
            , input
                [ placeholder "State"
                , title "Current state"
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
                , title "Empty symbol"
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
                [ placeholder "X"
                , title "Final state"
                , value model.currentFinalStateString
                , class "current-final-state-input"
                , classIf (Maybe.isJust model.currentFinalStateValidationError) "invalid"
                , onInput UpdateFinalState
                ]
                []
            , span
                [ attribute "error" (Maybe.withDefault "" model.currentFinalStateValidationError) ]
                []
            ]
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


savedMachinesHtmls : Model -> List (Html Msg)
savedMachinesHtmls model =
    model.savedMachines
        |> Dict.keys
        |> List.map
            (\name ->
                a
                    [ class "saved-machine-link"
                    , onClick (LoadMachine name)
                    ]
                    [ text name ]
            )


view : Model -> Html Msg
view model =
    div
        [ class "app-layout" ]
        [ section
            [ class "info-container" ]
            [ header [] [ text "overview" ]
            , text
                """
                A Turing machine is a mathematical model of computation that defines an abstract machine that manipulates symbols
                on a strip of tape according to a table of rules. Despite the model's simplicity, given any computer algorithm,
                a Turing machine capable of implementing that algorithm's logic can be constructed.
                The machine operates on an infinite memory tape divided into discrete "cells".
                The machine positions its "head" over a cell and "reads" or "scans" the symbol there.
                Then, based on the symbol and the machine's own present state in a "finite table" of user-specified instructions,
                the machine first writes a symbol into the cell, then moves the tape one cell left or right,
                then, based on the observed symbol and the machine's own state in the table, either proceeds to another instruction
                or halts computation.
                """
            ]
        , section
            [ class "options-container" ]
            [ text "" ]
        , section
            [ class "header-container" ]
            [ header [] [ text "turing.elm" ] ]
        , section
            [ class "app-container" ]
            [ header [] [ text "simulation" ]
            , div [ class "simulation-controls" ]
                [ stateAndTapeHtml model
                , configurationHtml model
                , controlsHtml model
                , rulesListHtml model
                ]
            ]
        , section
            [ class "saved-machines-container" ]
            (header [] [ text "examples" ] :: savedMachinesHtmls model)
        , section
            [ class "footer-container" ]
            [ hr [] []
            , span [] [ text "Source code available at " ]
            , a [ href "https://github.com/ivxvm/turing-elm" ] [ text "github" ]
            , span [] [ text ", together with dev " ]
            , a [ href "https://github.com/ivxvm/turing-elm/blob/master/notes.md" ] [ text "notes" ]
            , span [] [ text "." ]
            ]
        ]
