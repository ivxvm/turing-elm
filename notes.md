Elm notes:

* Elm can't deal with cyclic module dependencies on its own, code should be restructured by hand. The way I did it here is separate ComputationWorkflow [Type](https://github.com/ivxvm/turing-elm/blob/master/src/App/ComputationWorkflow/Type.elm) / [Impl](https://github.com/ivxvm/turing-elm/blob/master/src/App/ComputationWorkflow/Impl.elm) files for functions and type definition.

* Elm doesn't seem to have module reexports, neither an alternative to folder/index.js

* Elm doesn't have nested record update syntax.
This works: `{ obj | field = newValue }`
This doesn't: `{ obj | field = { obj.field | other = ... } }`

* There is a neat idiom for field setters that [plays well](https://github.com/ivxvm/turing-elm/blob/master/src/App/Update.elm#L155) with pipeline operator `(|>)`:

  ```elm
  setSomething : FieldType -> RecordType -> RecordType
  setSomething ... = ...

  asSomethingIn : RecordType -> FieldType -> RecordType
  asSomethingIn = flip setSomething
  ```

* Elm does have row polymorphism which enables some interesting code separation, composition and reuse patterns (see [Tape](https://github.com/ivxvm/turing-elm/blob/master/src/Core/Tape.elm) / [KeyedTape](https://github.com/ivxvm/turing-elm/blob/master/src/Core/KeyedTape.elm)), but it's limited and can't achieve certain things like polymorphic record merge (like `Object.assign` from JavaScript).

* Elm doesn't have anything like typeclasses (Haskell), traits (Rust), or module signatures / functors (Standard ML / OCaml), which penalizes certain kinds of polymorphism and generic programming. For example when I realized I need keys in Tape, I was able to easily make an adapter KeyedTape using row polymorphism and composition, but I couldn't easily change Turing to use KeyedTape instead of Tape, I had to modify code and make it hardwired to new KeyedTape. It's possible to achieve the same by passing all overloadable functions as parameters, which I sometimes did for toString/fromString and encode/decode, but for the former case I was too lazy to try given the fact that I don't actually need it to be polymorphic atm. I think this approach is worth exploring further though. It has a benefit of everything being simple functions which means it might be possible to come up with systematic set of higher order functions automating the hassle.

* Having things like typeclasses, traits, or module signatures / functors, would lead to more generic and thus complicated APIs which arguably is what Elm tries to avoid. Worth noting, it's the same argument that people apply when arguing that Go doesn't need generics. It's all about where to draw the line. Great language designers struggle whether they should sacrifice abstraction or simplicity, while languages not that great suck at both.

* Even though I couldn't find any info on higher order reducers in Elm, the pattern works just as well for update functions. Check [withScrollUpdate](https://github.com/ivxvm/turing-elm/blob/master/src/App/UpdateScroll.elm#L31) for an example.

* Overall, Elm feels very similar to basic React/Redux, but way cleaner and elegant, with language being a much better fit for this style of programming. However, Elm doesn't seem to have any alternatives to things like react-hooks and when you need to do something that doesn't fit into purely functional vdom realm, you have to do it all by yourself on the javascript side and interface with Elm code via ports or custom elements. Also Elm doesn't seem to have alternatives to advanced process sequencing libraries like redux-saga and you have to figure out solutions to such problems on your own. For example, when I needed certain delayed Cmds to be cancellable I had to come up with ComputationWorkflow which stores id of process it represents and [checks if id of newly arrived workflow Cmd is still valid](https://github.com/ivxvm/turing-elm/blob/master/src/App/ComputationWorkflow/Impl.elm#L33).

* Tooling is decent and everything works as intended out of the box on Mac M1. There are minor issues in VSCode Elm language server, like type errors sometimes not showing up until you edit and save file again, but it doesn't happen often and isn't too annoying.

* Builtin "elm reactor" doesn't seem to support external CSS. I generally have to spend a lot of time messing around with CSS to get things right and this is why I'm not a fan of doing CSS in code. It's ofcourse great to keep things locally scoped but it's very time consuming for me to edit styles without proper CSS intellisense and figuring out how to rephrase combinations of selectors and pseudoselectors in code. The only one time I liked this approach is Styled Components library which provides template literals containing just straight CSS (making it easy to repurpose existing CSS syntax highlighting and intellisense) but with few extra features like variable interpolation (and ofcourse renaming everything making it effectively locally scoped). There is an alternative to elm reactor called elm-live which makes it easy to use external CSS and it works just fine for me (except it appends text node "undefined" at the end of body, but that didn't hurt much).

* Turns out, some things I implemented on JavaScript side are doable in Elm by using APIs from Browser.* modules, which I initially overlooked. Watching youtube presentations and reading code in publicly available github repositories helps a lot to discover new things about Elm.

Other notes:

* Vdom creates a lot of tricky issues with CSS transitions, because of implicit element insertions and deletions. At one point I had to write the whole new KeyedTape replacing Tape just to keep track of cell keys to control rendering. Later I also realized I needed to render some elements prematurely. All to be able to do CSS transitions.

* Trick for opacity gradients using "mix-blend-mode: hard-light" and gray color stops: https://stackoverflow.com/a/15624692

* Safari doesn't support outlines with rounded corners, the same can be achieved with box-shadow as a workaround

* Safari needs prefix for user-select: "-webkit-user-select"
