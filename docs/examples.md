# Examples

Attention: ``checkStr`` will complain bitterly in case you give it an un-typed expression for lambda or let-rec expressions!

Table of Contents:
* [Let](#let)
* [Let Rec Typed](#let-rec-typed)
* [Let Rec Untyped](#let-rec-un-typed)
* [Lambda Typed](#lam-typed)
* [Lambda Untyped](#lam-un-typed)
* [Comments](#comments)
* [Closures](#closures)
* [Shadowing](#shadowing)

## Let
```ocaml
evalStr "let x = if 3 <= 4 then true else false in x" ;;
```
Result:
```ocaml
- : value = Bval true
```

## Let Rec (typed)
```ocaml
evalStr "let rec fac (a : Int) : Int = fun n ->
if n <= 1 then a else fac (n*a) (n-1) 
in fac 1 5" ;;
```
Result:
```ocaml
- : value = Ival 120
```

## Let Rec (un-typed)
```ocaml
evalStr "let rec f x = if 1 <= 2 then 4 else 2 in f 1" ;;
```
Result:
```ocaml
- : value = Ival 4
```

## Lam (typed)
```ocaml
evalStr "let f = fun x : Int -> if x <= 3 then true else false in f 2" ;;
```
Result:
```ocaml
- : value = Bval True
```

## Lam (un-typed)
```ocaml
evalStr "let f = fun x -> if x <= 3 then true else false in f 2" ;;
```
Result:
```ocaml
- : value = Bval True
```

## Comments
```ocaml
evalStr "let x = 1 (* this is a comment *) in x (* this is another comment *)" ;;
```
Result:
```ocaml
- : value = Ival 1
```

## Closures
```ocaml
evalStr "let f = fun x -> x * 2 in f" ;;
```
Result:
```ocaml
- : value = Closure ("x", Oapp (Mul, Var "x", Con (Icon 2)), [])
```

## Shadowing
```ocaml
evalStr "let f = fun x -> x * 2 in let g = f in g" ;;
```
Shadowing function ``f`` (takes ``x`` as argument) with ``g``.  
Result:
```ocaml
- : value = Closure ("x", Oapp (Mul, Var "x", Con (Icon 2)), [])
```
