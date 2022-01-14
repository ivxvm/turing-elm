module Main exposing (..)

import App.Model as App exposing (..)
import App.Msg exposing (..)
import App.Turing.BusyBeaver as BusyBeaver
import App.Update as App
import App.UpdateScroll exposing (withScrollUpdate)
import App.View as App
import Browser
import Html.Styled exposing (toUnstyled)


main : Program () Model Msg
main =
    Browser.element
        { init = \() -> App.init BusyBeaver.turing
        , update = withScrollUpdate App.update
        , view = App.view >> toUnstyled
        , subscriptions = \_ -> Sub.none
        }
