# Bad examples

Table of Contents:
* [Illegal application](#illegal-application)
* [Illegal operators](#illegal-operators)
* [Free variables](#free-variables)
* [Ill-types](#ill-types)
* [Not empty tokenlist](#not-empty-tokenlist)

## Illegal application
```ocaml
evalStr "1 1" ;;
```
Exception:
```ocaml
Exception: (Failure "eval_fun: function does not take arguments")
```

## Illegal operators
```ocaml
evalStr "1 + false" ;;
evalStr "-1" ;;
evalStr "1 +" ;;
```
Exception:
```ocaml
Exception: (Failure "eval_op: unexpected value")
...
```

## Free Variables
```ocaml
evalStr "let x = y + 1 in x" ;;
```
Exception:
```ocaml
Exception: (Failure "lookup: unbound value")
```

## Ill-Types
```ocaml
checkStr "let x = if 2 <= 3 then true else 3 in x" ;;
```
Exception:
```ocaml
Exception: (Failure "check_if: 'if' is ill-typed")
```

## Not empty Tokenlist
```ocaml
evalStr "let x = 1 in x in" ;;
```
Exception:
```ocaml
Exception: (Failure "exp: token list is not empty")
```
