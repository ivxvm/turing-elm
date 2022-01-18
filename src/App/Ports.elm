port module App.Ports exposing (..)

import Json.Encode as E


port centerCurrentTapeCell : () -> Cmd msg


port scrollTape : Int -> Cmd msg


port provideBuiltinMachines : List ( String, E.Value ) -> Cmd msg


port onProvideBuiltinMachinesSuccess : (() -> msg) -> Sub msg


port saveMachine : ( String, E.Value ) -> Cmd msg


port getSavedMachines : () -> Cmd msg


port onGetSavedMachinesSuccess : (List ( String, String ) -> msg) -> Sub msg


port onDeleteMachineSuccess : (String -> msg) -> Sub msg
