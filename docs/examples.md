# Examples

## Let (typed)
```ocaml
evalStr "let x : Int = 3 in x" ;;
```

## Let (un-typed)
```ocaml
evalStr "let x = if 3 <= 4 then true else false in x" ;;
```

## Let Rec (typed)
```ocaml
evalStr "let rec fac (a : Int) : Int = fun n ->
if n <= 1 then a else fac (n*a) (n-1) 
in fac 1 5" ;;
```

## Let Rec (un-typed)
```ocaml
evalStr "let rec f x = if 1 <= 2 then 4 else 2 in f 1" ;;
```

Work in progress ...
