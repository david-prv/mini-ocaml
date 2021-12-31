# Mini-OCaml Interpreter
Small interpreter written in Meta-Language OCaml for Object-Language "Mini-OCaml"

## Table of contents
1. [ToDo Features](https://github.com/david-prv/mini-ocaml#todo-features)
2. [Abstract Grammar](https://github.com/david-prv/mini-ocaml#abstract-grammar)
3. [Usage](https://github.com/david-prv/mini-ocaml#usage)
    * [Working Examples](https://github.com/david-prv/mini-ocaml#working-examples)
5. [How does it work](https://github.com/david-prv/mini-ocaml#how-does-it-work)
    * [4 Layers](https://github.com/david-prv/mini-ocaml#4-layers) 
    * [Workflow](https://github.com/david-prv/mini-ocaml#workflow) 

## ToDo Features:
- [ ] Lexer / Tokenizer
- [ ] Parser
- [x] Check for free Vars
- [x] Type Checking / Guessing
- [x] Evaluation

## Abstract Grammar
```bnf
<cons> ::= c ∈ 𝔹 | ℕ
<var> ::= string
<type> ::= <cons> | <type> → <type>
<operator> ::= ⊕ | ⊖ | ⊗ | ≤
<expression> ::= <var> | <cons> | <expression> ∘ <expression> | <expression> <expression>
                | IF <expression> THEN <expression> ELSE <expression>
                | 𝜆<var>.<expression> | 𝜆<var>:<type>.<expression>
                | LET <var> = <expression> IN <expression>
                | LET REC <var> <var> = <expression> IN <expression>
                | LET REC <var> (<var>:<type>) : <type> = <expression> IN <expression>
```

## Usage
First, you'll need to download the .ML file and run interpreter in any [OCaml environment](https://github.com/david-prv/mini-ocaml/blob/main/docs/environments.md)!
The following commands will be our top-level commands:
```
checkStr : string → type
evalStr : string → value
```
### Working examples
#### Simple let expression
```ocaml
let input = "let x = 3 in x" ;;
checkStr input ;;
evalStr input ;;
```
#### If expression
```ocaml
let input = "let x = if 3 <= 4 then true else false in x" ;;
checkStr input ;;
evalStr input ;;
```
#### Recursive expression
```ocaml
let input = "let rec f x = if x <= 4 then f (x-1) else false in x" ;;
checkStr input ;;
evalStr input ;;
```
#### Complex recursive expression
```ocaml
let input = "let rec fac a = fun n ->
    if n <= 1 then a else fac (n*a) (n-1) 
   in fac 1 5" ;;
checkStr input ;;
evalStr input ;;
```
#### Lambda expression
```ocaml
let input = "let f = fun x -> x + 1 in f 1" ;;
checkStr input ;;
evalStr input ;;
```
#### Typed recursive expressions
```ocaml
let input1 = "let f = fun x : Int -> x + 1 in f 1" ;;
let input2 = "let rec f (x : Int) : Int = if 1 <= 2 then 4 else 2 in f x" ;;

checkStr input1 ;;
checkStr input2 ;;

evalStr input1 ;;
evalStr input2 ;;
```

See more examples [here](https://github.com/david-prv/mini-ocaml/blob/main/docs/examples.md).

## How does it work
### 4 Layers
The interpreter is divided in 4 layers:
| Layer             | Layer Type |
|-------------------|------------|
| Lexical Syntax    | Static     |
| Phrasal Syntax    | Static     |
| Static Semantics  | Static     |
| Dynamic Semantics | Dynamic    |

### Workflow
It goes through every layer as follows:
  
1. Lexical Syntax: A provided string (assuming it's a mini-ocaml script) will first of all be converted to a list of so-called ``tokens`` (read more about [tokenizer/lexer](https://bit.ly/3HAZn9x))  
↓
2. Phrasal Syntax: As a next step the token list will be interpreted as syntax tree, called ``parsing`` (what is a [parser](https://de.wikipedia.org/wiki/Parser)?)  
↓
3. Static Semantics: ``checkStr`` then does something, what is called ``algorithmic reading``, what will check the type for the provided script and ofc for free variables.  
↓
4. Dynamic Semantics: ``evalStr`` will now take the lexed and parsed syntax tree and execute it in its logical order. After that, you will finally get a value as result.
