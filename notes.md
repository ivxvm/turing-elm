Trick for opacity gradients using "mix-blend-mode: hard-light" and gray color stops:
https://stackoverflow.com/a/15624692

Elm can't deal with cyclic module dependencies on its own, code should be restructured by hand
(the way I did it here is separate ComputationWorkflow Impl/Type files for functions and type definition)

Elm doesn't seem to have module reexports, neither an alternative to folder/index.js

Elm doesn't have nested record update syntax
this works: { obj | field = newValue }
this doesn't: { obj | field = { obj.field | other = ... } }
