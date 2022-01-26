module Main exposing (..)

import App.Model as App exposing (..)
import App.Msg exposing (..)
import App.Ports as Ports
import App.Turing.BitInverter as BitInverter
import App.Turing.BusyBeaver as BusyBeaver
import App.Update as App
import App.UpdateScroll exposing (withScrollUpdate)
import App.View as App
import Browser
import Browser.Events exposing (onKeyDown, onKeyUp)
import Core.Turing as Turing
import Html.Styled exposing (toUnstyled)
import Json.Decode as D


main : Program () Model Msg
main =
    Browser.element
        { init =
            \() ->
                let
                    ( model, initCmd ) =
                        App.init "Bit-Inverter" BitInverter.turing
                in
                ( model
                , Cmd.batch
                    [ initCmd
                    , Ports.provideBuiltinMachines
                        [ ( "Busy-Beaver", Turing.encodeSimple BusyBeaver.turing )
                        , ( "Bit-Inverter", Turing.encodeSimple BitInverter.turing )
                        ]
                    ]
                )
        , update =
            withScrollUpdate App.update
        , view =
            App.view >> toUnstyled
        , subscriptions =
            \_ ->
                Sub.batch
                    [ Ports.onProvideBuiltinMachinesSuccess (\() -> GetSavedMachines)
                    , Ports.onGetSavedMachinesSuccess GetSavedMachinesSuccess
                    , Ports.onDeleteMachineSuccess DeleteMachine
                    , onKeyDown (D.map KeyDown (D.field "key" D.string))
                    , onKeyUp (D.map KeyUp (D.field "key" D.string))
                    ]
        }
