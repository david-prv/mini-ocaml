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
evalStr "let rec f (x : Int) : Int = if 1 <= 2 then 4 else 2 in f x" ;;
```

## Let Rec (un-typed)
```ocaml
evalStr "let rec f x = if 1 <= 2 then 4 else 2 in f x" ;;
```

Work in progress ...
