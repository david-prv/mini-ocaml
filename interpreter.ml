(* TYPE DECLARATIONS *)

type ('a, 'b) env = ('a * 'b) list
type var = string ;;
type con = Bcon of bool | Icon of int 
type op  = Add
         | Sub
         | Mul
         | Leq 
type ty = Bool 
        | Int
        | Arrow of ty * ty 
type exp = Var of var | Con of con
         | If of exp * exp * exp
         | Lam of var * exp 
         | Oapp of op * exp * exp
         | Fapp of exp * exp 
         | Let of var * exp * exp
         | Letrec of var * var * exp * exp
         | Lamty of var * ty * exp 
         | Letrecty of var * var * ty * ty * exp * exp 
type value = Bval of bool
           | Ival of int
           | Closure of var * exp * (var,value) env
           | Bclosure of var * var * exp * (var,value) env 
type token = LP | RP | EQ | COL | ARR | LAM | ADD | SUB | MUL | LEQ
           | IF | THEN | ELSE | LET | REC | IN | CON of con | VAR of string | BOOL | INT
  
(* HELPER FUNCTIONS *)

let empty : ('a, 'b) env = []
let update (environment : ('a,'b) env) key value : ('a,'b) env =
  (key, value) :: environment
                       
let rec mem x l =
  match l with
  | [] -> false
  | y :: l -> (x = y) || mem x l
                
let rec lookup x (env : ('a,'b) env) =
  match env with
  | (key, value) :: t -> if key = x then value else lookup x t
  | [] -> failwith "lookup: unbound value"
                
(* LEXER / TOKENIZER *) 

let rec verify_if t = 
  match t with
  | [] -> false
  | 't'::'h'::'e'::'n'::t -> begin
      let rec verify_if' t =
        match t with
        | [] -> false
        | 'e'::'l'::'s'::'e'::t -> true
        | _ :: t -> verify_if' t
      in verify_if' t
    end
  | _ :: t -> verify_if t
                
let rec verify_let t = 
  match t with
  | [] -> false
  | 'r'::'e'::'c'::_::f::_::x::t -> verify_let' t 
  | _::x::_::'='::t -> verify_let' t
  | _ :: t -> verify_let t
and verify_let' t =
  match t with
  | [] -> false
  | 'i'::'n'::t -> true
  | _ :: t -> verify_let' t 
                
let rec verify_fun t = true ;;

let lex s =
  let n = String.length s in
  let explode s =
    let rec explode' s i a =
      if i = String.length s then a
      else explode' s (i+1) (a @ [String.get s i])
    in explode' s 0 [] in
  let rec lex i l =
    if i >= n then List.rev l
    else match String.get s i with
      | '+' -> lex (i+1) (ADD::l)
      | '-' -> begin
          match String.get s (i+1) with
          | '>' -> lex (i+2) (ARR::l)
          | _ -> lex (i+1) (SUB::l)
        end
      | '*' -> lex (i+1) (MUL::l)
      | '(' -> lex (i+1) (LP::l)
      | ')' -> lex (i+1) (RP::l)
      | ':' -> lex (i+1) (COL::l)
      | '<' -> begin
          match String.get s (i+1) with
          | '=' -> lex (i+2) (LEQ::l)
          | _ -> failwith "lex: unknown operator '<'"
        end
      | '=' -> lex (i+1) (EQ::l)
      | ' ' | '\n' | '\t' -> lex (i+1) l
      | _ -> begin 
          let char_list = explode (String.sub s i ((String.length s) - i)) in 
          let rec lex_c cl tl i = match cl with
            | [] -> failwith "lex: expression is not exhaustive"
            | 'i'::'f'::t -> begin
                if verify_if t then
                  lex (i+2) (IF::tl)
                else
                  failwith "lex: 'if' syntax error"
              end
            | 't'::'h'::'e'::'n'::t -> lex (i+4) (THEN::tl)
            | 'e'::'l'::'s'::'e'::t -> lex (i+4) (ELSE::tl)
            | 'f'::'u'::'n'::t -> begin
                if verify_fun t then
                  lex (i+3) (LAM::tl)
                else
                  failwith "lex: 'fun' syntax error"
              end  
            | 'l'::'e'::'t'::t -> begin
                if verify_let t then
                  lex (i+3) (LET::tl)
                else
                  failwith "lex: 'let' syntax error"
              end
            | 'r'::'e'::'c'::t -> lex (i+3) (REC::tl)
            | 'i'::'n'::t -> lex (i+2) (IN::tl)
            | 't'::'r'::'u'::'e'::t | 'f'::'a'::'l'::'s'::'e'::t -> lex (i+1) (BOOL::tl)
            | x :: t -> match x with
              | '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' -> lex (i+1) (INT::tl)
              | _ -> lex (i+1) (VAR(String.make 1 x)::tl)
          in lex_c char_list l i
        end
  in lex 0 [] ;;

(* PARSER *)

(* TYPE CHECKER *)

let rec check env exp : ty = 
  match exp with
  | Con(con) -> begin
      match con with
      | Bcon(bool) -> Bool
      | Icon(int) -> Int 
    end
  | Var(var) -> lookup var env
  | Oapp(op,ex1,ex2) -> check_oapp op (check env ex1) (check env ex2)
  | Fapp(ex1,ex2) -> check_fapp (check env ex1) (check env ex2)
  | If(ex1,ex2,ex3) -> check_if (check env ex1) (check env ex2) (check env ex3)
  | Lam(_,_) -> failwith "check: missing lambda type"
  | Lamty(x,ty,ex) -> Arrow(ty, check (update env x ty) ex)
  | Let(x,ex1,ex2) -> check (update env x (check env ex1)) ex2
  | Letrec(f,x,ex1,ex2) -> failwith "check: missing let rec type"
  | Letrecty(f,x,ty1,ty2,ex1,ex2) -> Arrow(ty1, check (update env f (Arrow(ty1, ty2))) ex2)
and check_oapp op x1_ty x2_ty =
  match x1_ty, x2_ty with
  | Int, Int -> Arrow(x1_ty, x2_ty)
  | _, _ -> failwith "check_oapp: operation is ill-typed"
and check_fapp fun_ty exp_ty =
  match fun_ty with
  | Arrow(Int,t2) -> if exp_ty = Int then fun_ty else failwith "check_fapp: expression has unexpected type"
  | Arrow(Bool,t2) -> if exp_ty = Bool then fun_ty else failwith "check_fapp: expression has unexpected type"
  | _ -> failwith "check_fapp: Illegal application (no function given)"
and check_if ex1_ty ex2_ty ex3_ty =
  if ex1_ty = Bool then
    if ex2_ty = ex3_ty then ex2_ty
    else failwith "check_if: If is ill-typed"
  else failwith "check_if: If is ill-typed"
    

(* EVALUATION *)

let rec eval env exp : value =
  match exp with
  | Var x -> lookup x env
  | Con(con) -> begin
      match con with
      | Bcon(b) -> Bval b
      | Icon(i) -> Ival i
    end
  | Oapp(op,ex1,ex2) -> eval_op op (eval env ex1) (eval env ex2)
  | Fapp(ex1,ex2) -> eval_fun env ex1 ex2
  | If(ex1,ex2,ex3) -> eval_if env (eval env ex1) ex2 ex3
  | Lam(x,exp) | Lamty(x,_,exp) -> Closure (x,exp,env)
  | Let(x,ex1,ex2) -> eval (update env x (eval env ex1)) ex2
  | Letrec(f,x,ex1,ex2) | Letrecty(f,x,_,_,ex1,ex2) -> eval (update env f (Bclosure (f,x,ex1,env))) ex2
and eval_op op v1 v2 = match op, v1, v2 with
  | Add, Ival(i1), Ival(i2) -> Ival (i1 + i2)
  | Sub, Ival(i1), Ival(i2) -> Ival (i1 - i2)
  | Mul, Ival(i1), Ival(i2) -> Ival (i1 * i2)
  | Leq, Ival(i1), Ival(i2) -> Bval (i1 <= i2)
  | _ -> failwith "eval_op: unexpected value (maybe a closure?)"
and eval_fun env ex1 ex2 = let v1 = (eval env ex1) in match v1 with
  | Bclosure (f,x,e,env) -> eval (update (update env f v1) x (eval env ex2)) e
  | Closure (x,e,env) -> eval (update env x (eval env ex2)) e 
  | _ -> failwith "eval_fun: function does not take arguments (not a closure?)"
and eval_if env v ex1 ex2 = match v with
  | Bval(true) -> eval env ex1
  | Bval(false) -> eval env ex2
  | _ -> failwith "eval_if: unexpected value (maybe a closure?)"

(* CHECKSTR & EVALSTR *)  

let checkStr s = failwith "not done yet" ;;
let evalStr s = failwith "not done yet" ;;

(* TOPLEVEL *)

let test = lex "let x = 1 in x" ;;
let test' = lex "let x = if 1 <= 2 then 3 else 4 in x" ;;
let test'' = lex "let rec f x = if 1 <= 2 then 4 else 2 in f x" ;;

(*let env = empty ;;
let env' = empty ;;
let exp = (Con(Icon 1)) ;;
let exp' = (Var "x") ;;
let exp'' = (Oapp(Add, Con(Icon 1), Con(Icon 2))) ;;
let exp_lam = (Lamty("x", Int, Oapp(Add, Var "x", Con(Icon 2)))) ;; 
let exp_lr = (Letrecty("f", "x", Int, Int, Oapp(Add, Var "x", Con(Icon 2)), Lamty("y", Int, Oapp(Add, Var "y", Con(Icon 2))))) ;;
eval env exp'' ;; (* yields Ival 3 *)
eval env exp_lam ;; (* yields closure (x,e,V) *)
eval env' exp_lr ;; (* yields bclosure (f,x,e,V) *)
eval empty (Oapp(Leq,(Oapp(Add, Con(Icon 1), Con(Icon 3))), Con(Icon 5))) (* yields Bval true *)*)
