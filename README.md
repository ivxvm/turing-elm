# What is this?
An interactive [Turing machine](https://en.wikipedia.org/wiki/Turing_machine) simulator written in Elm. There are plenty of predefined machines to try. You can define your own machines and save to localstorage. Mobile friendly. Made to get a feel of both Elm programming and Turing machines as a model of mechanical computation. Development notes are available [here](https://github.com/ivxvm/turing-elm/blob/master/notes.md).

# Wanna try locally?
```
git clone https://github.com/ivxvm/turing-elm
cd turing-elm
npm i
elm make src/Main.elm --output bundle.js
npm run live
```
# Wanna be cool?
Implement and run a simulation of any [Universal Turing machine](https://en.wikipedia.org/wiki/Universal_Turing_machine). They are often large and very hard to understand, but there are machines in this class as small as just few dozens instructions. Program size for such machines seems usually large as well.
