module Core.Tape exposing (..)

import Basics.Extra exposing (flip)
import Core.Direction exposing (Direction(..))
import Json.Decode as D
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe


type alias Tape ext sym =
    { ext
        | left : List sym
        , right : List sym
        , currentSymbol : sym
        , emptySymbol : sym
    }


setEmptySymbol : a -> Tape ext a -> Tape ext a
setEmptySymbol symbol tape =
    { tape | emptySymbol = symbol }


asEmptySymbolIn : Tape ext a -> a -> Tape ext a
asEmptySymbolIn =
    flip setEmptySymbol


shiftLeft : Tape ext a -> Tape ext a
shiftLeft tape =
    case tape.left of
        x :: xs ->
            { tape | left = xs, right = tape.currentSymbol :: tape.right, currentSymbol = x }

        [] ->
            { tape
                | right = tape.currentSymbol :: tape.right
                , currentSymbol = tape.emptySymbol
            }


shiftRight : Tape ext a -> Tape ext a
shiftRight tape =
    case tape.right of
        x :: xs ->
            { tape | left = tape.currentSymbol :: tape.left, right = xs, currentSymbol = x }

        [] ->
            { tape
                | left = tape.currentSymbol :: tape.left
                , currentSymbol = tape.emptySymbol
            }


shift : Direction -> Tape ext a -> Tape ext a
shift direction tape =
    case direction of
        Left ->
            shiftLeft tape

        Right ->
            shiftRight tape


writeSymbol : a -> Tape ext a -> Tape ext a
writeSymbol newSymbol tape =
    { tape | currentSymbol = newSymbol }


currentSymbolIndex : Tape ext sym -> Int
currentSymbolIndex tape =
    List.length tape.left


toSymbolList : Tape ext a -> List a
toSymbolList tape =
    List.concat
        [ List.reverse tape.left
        , [ tape.currentSymbol ]
        , tape.right
        ]


fromString : (String -> Maybe a) -> a -> String -> Result String (Tape {} a)
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


toTapeString : (a -> String) -> Tape ext a -> String
toTapeString symToString tape =
    String.join " "
        (List.concat
            [ List.reverse (List.map symToString tape.left)
            , [ String.concat [ "[", symToString tape.currentSymbol, "]" ] ]
            , List.map symToString tape.right
            ]
        )


encode : (sym -> E.Value) -> Tape {} sym -> E.Value
encode encodeSymbol tape =
    E.object
        [ ( "left", E.list encodeSymbol tape.left )
        , ( "right", E.list encodeSymbol tape.right )
        , ( "currentSymbol", encodeSymbol tape.currentSymbol )
        , ( "emptySymbol", encodeSymbol tape.emptySymbol )
        ]


decoder : D.Decoder sym -> D.Decoder (Tape {} sym)
decoder symbolDecoder =
    D.map4
        (\l r c e ->
            { left = l
            , right = r
            , currentSymbol = c
            , emptySymbol = e
            }
        )
        (D.field "left" (D.list symbolDecoder))
        (D.field "right" (D.list symbolDecoder))
        (D.field "currentSymbol" symbolDecoder)
        (D.field "emptySymbol" symbolDecoder)
