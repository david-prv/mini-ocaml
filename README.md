# Mini-OCaml Interpreter
Small interpreter written in Meta-Language OCaml for Object-Language "Mini-OCaml"

## Planned Features
- Lexer / Tokenizer
- Parser
- Check for free Vars
- Type Checking / Guessing
- Evaluation

## Abstract Grammar
```bnf
<var> ::= string
<cons> ::= B | N
<type> ::= <cons>| <type> → <type>
<operator> ::= ⊕ | ⊖ | ⊗ | ≤
<expression> ::= <var> | <cons> | <expression> ∘ <expression> | <expression> <expression>
                | IF <expression> THEN <expression> ELSE <expression>
                | 𝜆<var>.<expression> | 𝜆<var>:<type>.<expression>
                | LET <var> = <expression> IN <expression>
                | LET REC <var> <var> = <expression> IN <expression>
                | LET REC <var> (<var>:<type>) : <type> = <expression> IN <expression>
```
