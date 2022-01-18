module Main exposing (..)

import App.Model as App exposing (..)
import App.Msg exposing (..)
import App.Ports as Ports
import App.Turing.BusyBeaver as BusyBeaver
import App.Update as App
import App.UpdateScroll exposing (withScrollUpdate)
import App.View as App
import Browser
import Core.Turing as Turing
import Html.Styled exposing (toUnstyled)
import Json.Encode as E


main : Program () Model Msg
main =
    Browser.element
        { init =
            \() ->
                let
                    ( model, initCmd ) =
                        App.init "Busy Beaver" BusyBeaver.turing
                in
                ( model
                , Cmd.batch
                    [ initCmd
                    , Ports.provideBuiltinMachines
                        [ ( "Busy Beaver", Turing.encode E.string E.string BusyBeaver.turing )
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
                    ]
        }
