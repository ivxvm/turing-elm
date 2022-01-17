port module App.Ports exposing (..)

import Json.Encode as E


port centerCurrentTapeCell : () -> Cmd msg


port scrollTape : Int -> Cmd msg


port saveMachine : ( String, E.Value ) -> Cmd msg


port getSavedMachines : () -> Cmd msg


port getSavedMachinesSuccess : (List ( String, String ) -> msg) -> Sub msg
