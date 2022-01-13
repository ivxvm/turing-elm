module Core.Tape exposing (..)

import Basics.Extra exposing (flip)
import Core.Direction exposing (Direction(..))
import List.Extra as List
import Maybe.Extra as Maybe


type alias Tape a =
    { left : List a
    , right : List a
    , currentSymbol : a
    , emptySymbol : a
    }


setEmptySymbol : a -> Tape a -> Tape a
setEmptySymbol symbol tape =
    { tape | emptySymbol = symbol }


asEmptySymbolIn : Tape a -> a -> Tape a
asEmptySymbolIn =
    flip setEmptySymbol


shiftLeft : Tape a -> Tape a
shiftLeft tape =
    case tape.left of
        x :: xs ->
            { tape | left = xs, right = tape.currentSymbol :: tape.right, currentSymbol = x }

        [] ->
            { tape
                | right = tape.currentSymbol :: tape.right
                , currentSymbol = tape.emptySymbol
            }


shiftRight : Tape a -> Tape a
shiftRight tape =
    case tape.right of
        x :: xs ->
            { tape | left = tape.currentSymbol :: tape.left, right = xs, currentSymbol = x }

        [] ->
            { tape
                | left = tape.currentSymbol :: tape.left
                , currentSymbol = tape.emptySymbol
            }


shift : Direction -> Tape a -> Tape a
shift direction tape =
    case direction of
        Left ->
            shiftLeft tape

        Right ->
            shiftRight tape


writeSymbol : a -> Tape a -> Tape a
writeSymbol newSymbol tape =
    { tape | currentSymbol = newSymbol }


toSymbolList : Tape a -> ( List a, Int )
toSymbolList tape =
    let
        symbols =
            List.concat
                [ tape.left
                , [ tape.currentSymbol ]
                , tape.right
                ]

        currentSymbolIndex =
            List.length tape.left
    in
    ( symbols, currentSymbolIndex )


fromString : (String -> Maybe a) -> a -> String -> Result String (Tape a)
fromString parseSymbol emptySymbol string =
    let
        parseOptionalBrackets : String -> ( Bool, String )
        parseOptionalBrackets s =
            let
                isBracketed =
                    String.startsWith "[" s && String.endsWith "]" s

                remainingChars =
                    if isBracketed then
                        String.slice 1 -1 s

                    else
                        s
            in
            ( isBracketed, remainingChars )

        unwrapSecond : ( x, Maybe y ) -> Maybe ( x, y )
        unwrapSecond ( a, mb ) =
            Maybe.unwrap Nothing (\b -> Just ( a, b )) mb

        substrings =
            String.split " " string
                |> List.filter (not << String.isEmpty)

        maybeSymbols =
            substrings
                |> List.map
                    (\s ->
                        parseOptionalBrackets s
                            |> Tuple.mapSecond parseSymbol
                            |> unwrapSecond
                    )
                |> Maybe.combine
    in
    Result.fromMaybe "Parse error" maybeSymbols
        |> Result.andThen
            (\symbols ->
                List.findIndex Tuple.first symbols
                    |> Result.fromMaybe "Initial symbol not specified"
                    |> Result.map (\index -> ( symbols, index ))
            )
        |> Result.andThen
            (\( symbols, focusedSymbolIndex ) ->
                case List.splitAt focusedSymbolIndex symbols of
                    ( left, ( _, current ) :: right ) ->
                        Ok
                            { left = List.map Tuple.second left
                            , right = List.map Tuple.second right
                            , currentSymbol = current
                            , emptySymbol = emptySymbol
                            }

                    _ ->
                        Err "Unexpected split error"
            )


toTapeString : (a -> String) -> Tape a -> String
toTapeString symToString tape =
    String.join " "
        (List.concat
            [ List.map symToString tape.left
            , [ String.concat [ "[", symToString tape.currentSymbol, "]" ] ]
            , List.map symToString tape.right
            ]
        )
