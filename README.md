# Mini-OCaml Interpreter
Small interpreter written in Meta-Language OCaml for Object-Language "Mini-OCaml"

## Table of contents
1. [Planned Features](https://github.com/david-prv/mini-ocaml#planned-features)
2. [Abstract Grammar](https://github.com/david-prv/mini-ocaml#abstract-grammar)
3. [Usage & Examples](https://github.com/david-prv/mini-ocaml#usage)
4. [How does it work](https://github.com/david-prv/mini-ocaml#how-does-it-work)

## Planned Features
* Lexer / Tokenizer
* Parser
* Check for free Vars
* Type Checking / Guessing
* Evaluation

## Abstract Grammar
```bnf
<var> ::= string
<cons> ::= 𝔹 | ℕ
<type> ::= <cons>| <type> → <type>
<operator> ::= ⊕ | ⊖ | ⊗ | ≤
<expression> ::= <var> | <cons> | <expression> ∘ <expression> | <expression> <expression>
                | IF <expression> THEN <expression> ELSE <expression>
                | 𝜆<var>.<expression> | 𝜆<var>:<type>.<expression>
                | LET <var> = <expression> IN <expression>
                | LET REC <var> <var> = <expression> IN <expression>
                | LET REC <var> (<var>:<type>) : <type> = <expression> IN <expression>
```

## Usage
1. Download .SML file and run interpreter in any OCaml environment
2. Use toplevel for commands
3. Use following commands to run a mini-ocaml script:
```
checkStr : string → type
evalStr : string → value
```
4. Some examples:
```ocaml
(* simple let expression *)
let input = "let x = 3 in x" ;;
checkStr input ;;
evalStr input ;;

(* if-structure *)
let input = "let x = if 3 <= 4 then true else false in x" ;;
checkStr input ;;
evalStr input ;;

(* recursive expression *)
let input = "let rec f x = if x <= 4 then f (x-1) else false in x" ;;
checkStr input ;;
evalStr input ;;

(* lambda expression *)
let input = "let f = fun x -> x + 1 in f 1" ;;
checkStr input ;;
evalStr input ;;
```

## How does it work
1. A provided string (assuming it's a mini-ocaml script) will first of all be converted to a list of so-called ``tokens`` (read more about [tokenizer](https://bit.ly/3HAZn9x))
2. As a next step the token list will be interpreted as syntax tree, called ``parsing`` (what is a [parser](https://de.wikipedia.org/wiki/Parser)?)
3. ``checkStr`` then does something, what is called ``algorithmic reading``, what will check the type for the provided script and ofc for free variables.
4. ``evalStr`` will now take the lexed and parsed syntax tree and execute it in its logical order. After that, you will finally get a value as result.
