port module App.Ports exposing (..)


port centerCurrentTapeCell : () -> Cmd msg


port scrollTape : Int -> Cmd msg
