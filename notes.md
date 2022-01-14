* Trick for opacity gradients using "mix-blend-mode: hard-light" and gray color stops: https://stackoverflow.com/a/15624692

* Vdom creates a lot of tricky issues with css transitions, because of implicit element insertions and deletions.

* Elm can't deal with cyclic module dependencies on its own, code should be restructured by hand. The way I did it here is separate ComputationWorkflow Type / Impl (insert links) files for functions and type definition.

* Elm doesn't seem to have module reexports, neither an alternative to folder/index.js

* Elm doesn't have nested record update syntax.
This works: `{ obj | field = newValue }`
This doesn't: `{ obj | field = { obj.field | other = ... } }`

* There is a neat idiom for field setters that plays well with pipeline operator `(|>)`:
```elm
setSomething : FieldType -> RecordType -> RecordType
setSomething ... = ...

asSomethingIn : RecordType -> FieldType -> RecordType
asSomethingIn = flip setSomething
```

* Elm does have row polymorphism which enables some interesting code composition and reuse patterns (see Tape / KeyedTape (insert links) in repo), but it's limited and can't achieve certain things like polymorphic record merge (like `Object.assign` from JavaScript).

* Elm doesn't have module signatures / functors from Standard ML / OCaml which disables certain kinds of polymorphism and generic programming. For example when I realized I need keys in Tape, I was able to easily make an adapter KeyedTape using row polymorphism, but I couldn't easily change Turing to use KeyedTape instead of Tape, I had to modify code and make it hardwired to new KeyedTape.

* Having module signatures / functors, just like typeclasses, could probably lead to more complicated APIs which arguably is what Elm tries to avoid.

* Even though I couldn't find any info on higher order reducers in Elm, the pattern works just as well for update functions. Check withScrollUpdate (insert link) for an example.

* Overall, Elm feels very similar to basic React/Redux, but way cleaner and elegant, with language being a much better fit for this style of programming. However, Elm doesn't seem to have any alternatives to things like react-hooks and when you need to do something that doesn't fit into purely functional vdom realm, you have to do it all by yourself on the javascript side and interface with Elm code via ports or custom elements. Also Elm doesn't seem to have alternatives to advanced process sequencing libraries like redux-saga and you have to figure out solutions to such problems on your own. For example, when I needed certain delayed Cmds to be cancellable I had to come up with ComputationWorkflow which stores id of process it represents and checks if id of newly arrived workflow Cmd is still valid (insert link).
