Trick for opacity gradients using "mix-blend-mode: hard-light" and gray color stops:
https://stackoverflow.com/a/15624692

Vdom creates a lot of tricky issues with css transitions, because of implicit element insertions and deletions

Elm can't deal with cyclic module dependencies on its own, code should be restructured by hand
(the way I did it here is separate ComputationWorkflow Impl/Type files for functions and type definition)

Elm doesn't seem to have module reexports, neither an alternative to folder/index.js

Elm doesn't have nested record update syntax
this works: { obj | field = newValue }
this doesn't: { obj | field = { obj.field | other = ... } }

There is a neat idiom for field setters that plays well with pipeline operator (|>):
setSomething : FieldType -> RecordType -> RecordType
setSomething ... = ...
asSomethingIn : RecordType -> FieldType -> RecordType
asSomethingIn = flip setSomething

Elm does have row polymorphism which enables some interesting code composition and reuse patterns (see Tape/KeyedTape in repo),
but it's limited and can't achieve certain things like polymorphic record merge (like Object.assign from JS)

Elm doesn't have module signatures / functors from Standard ML / OCaml which disables certain kinds
of polymorphism and generic programming (for example when I realized I need keys in tape, I was able to easily make an
adapter KeyedTape using row polymorphism, but I couldn't easily change Turing to use KeyedTape instead of Tape,
I had to modify code and make it hardwired to new KeyedTape)

Having module signatures / functors, just like typeclasses,
could probably lead to more complicated APIs which arguably is what Elm tries to avoid
