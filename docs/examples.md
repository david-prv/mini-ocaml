# Examples

Attention: ``checkStr`` will complain bitterly in case you give it an un-typed expression for lambda or let-rec expressions!

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

## Lam (un-typed)
```ocaml
evalStr "let f = fun x -> if x <= 3 then true else false in f 2" ;;
```
Result:
```ocaml
- : value = Bval True
```

## Lam (typed)
```ocaml
evalStr "let f = fun x : Int -> if x <= 3 then true else false in f 2" ;;
```
Result:
```ocaml
- : ty = Bval True
```
