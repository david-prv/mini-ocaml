(* ------ TYPE DECLARATIONS ------ *)

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
type token = CO | CC | LP | RP | EQ | COL | ARR | LAM | ADD | SUB | MUL | LEQ | TY of ty
           | IF | THEN | ELSE | LET | REC | IN | CON of con | VAR of string | BOOL | INT
  
(* ------ HELPER FUNCTIONS ------ *)

let char2digit s =
  let s = String.make 1 s in
  match s with
  | "0" -> 0 | "1" -> 1 | "4" -> 4 | "7" -> 7
  | "2" -> 2 | "5" -> 5 | "8" -> 8
  | "3" -> 3 | "6" -> 6 | "9" -> 9
  | _ -> failwith "char2digit: unknown character"

let empty : ('a, 'b) env = []
let update (environment : ('a,'b) env) key value : ('a,'b) env =
  (key, value) :: environment
        
let fst (a, b) = match b with
  | [] -> a
  | _ -> failwith "exp: token list is not empty"
               
let rec mem x l =
  match l with
  | [] -> false
  | y :: l -> (x = y) || mem x l
                
let rec lookup x (env : ('a,'b) env) =
  match env with
  | (key, value) :: t -> if key = x then value else lookup x t
  | [] -> failwith "lookup: unbound value"
                
let verify t l =  match l with
  | [] -> failwith "verify: no list provided"
  | t'::l -> if t'=t then l else failwith "verify: no match" 
          
let isSymbol c =
  match c with
  | '+' | '-' | '>' | '<' | '=' | '(' | ')' | ':' | '*' | ' ' -> true 
  | _ -> false
    
let rec makeVar t : int * string =
  let c = 0 in
  let rec makeVar' count t akku : int * string =
    match t with
    | [] -> (count, akku) 
    | x::t -> if isSymbol x then (count,akku) else makeVar' (count+1) t (akku ^ (String.make 1 x)) 
  in makeVar' c t ""   
    
let rec skip (tl : token list) (akku : token list) : token list =
  match tl with
  | CO::l -> begin
      let rec skip' l =
        match l with
        | CC::l -> begin
            let rec close l =
              match l with
              | CC::l -> close l
              | x::l -> x::l
              | [] -> []
            in close l
          end
        | x::l -> skip' l
        | [] -> failwith "skip: comment not closed"
      in skip (skip' l) akku
    end
  | x::l -> skip l ([x] @ akku)
  | [] -> List.rev akku
          
(* ------ LEXER / TOKENIZER ------ *) 
    
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
  | _::x::'='::t -> verify_let' t
  | _ :: t -> verify_let t
and verify_let' t =
  match t with
  | [] -> false 
  | 'i'::'n'::t -> true
  | _ :: t -> verify_let' t 
                
let rec verify_fun t =
  match t with
  | [] -> false
  | _::x::_::':'::t -> verify_fun' t
  | _::x::':'::t -> verify_fun' t
  | _::x::_::'-'::'>'::t -> true
  | _::x::'-'::'>'::t -> true
  | _ -> false
and verify_fun' t =
  match t with
  | '-'::'>'::t -> true 
  | x::t -> verify_fun' t 
  | [] -> false 

let lex (s : string) =
  let n = String.length s in
  let s = String.lowercase_ascii s in
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
      | '*' -> begin
          match String.get s (i+1) with
          | ')' -> lex (i+2) (CC::l)
          | _ -> lex (i+1) (MUL::l)
        end
      | '(' -> begin
          match String.get s (i+1) with
          | '*' -> lex (i+2) (CO::l)
          | _ -> lex (i+1) (LP::l)
        end
      | ')' -> lex (i+1) (RP::l)
      | ':' -> begin
          let char_list = explode(String.sub s i ((String.length s) - i)) in
          let rec lex_ty cl tl i = match cl with
            | 'i'::'n'::'t'::t -> lex (i+3) (TY(Int)::COL::tl)
            | 'b'::'o'::'o'::'l'::t -> lex (i+4) (TY(Bool)::COL::tl)
            | ' '::t -> lex_ty t tl (i+1)
            | _ :: t -> lex_ty t tl (i+1)
            | [] -> failwith "lex: type syntax error"
          in lex_ty char_list l i
        end
      | '<' -> begin
          match String.get s (i+1) with
          | '=' -> lex (i+2) (LEQ::l)
          | _ -> failwith "lex: unknown operator '<'"
        end
      | '=' -> lex (i+1) (EQ::l)
      | ' ' | '\n' | '\t' -> lex (i+1) l
      | _ -> begin 
          let char_list = explode (String.sub s i ((String.length s) - i)) in 
          let lex_c cl tl i = match cl with
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
            | 'i'::'n'::t -> begin 
                match t with | 't'::t -> lex (i+3) (TY(Int)::tl)
                             | _ -> lex (i+2) (IN::tl)
              end
            | 't'::'r'::'u'::'e'::t -> lex (i+4) (CON(Bcon true)::tl)
            | 'f'::'a'::'l'::'s'::'e'::t -> lex (i+5) (CON(Bcon false)::tl)
            | x :: t -> match x with
              | '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' -> lex (i+1) (CON(Icon(char2digit x))::tl)
              | _ -> match t with 
                | y::t -> let (j,str) = makeVar (x::y::t) in lex (i+j) (VAR(str)::tl) 
                | _ -> lex (i+1) (VAR(String.make 1 x)::tl)
          in lex_c char_list l i
        end
  in lex 0 [] ;;

(* ------ PARSER ------ *) 

let rec typer l : ty * token list = 
  let (t,l) = pty l in ty' t l
and ty' t1 l = match l with 
  | ARR::l ->
      let (t2,l) = pty l in
      let (t,l) = ty' t2 l in
      (Arrow (t1,t),l)
  | l -> (t1,l)
and pty l = match l with
  | TY(Bool)::l -> (Bool, l)
  | TY(Int)::l -> (Int, l)
  | LP::l -> let (t,l) = typer l in (t, verify RP l)
  |  _ -> failwith "typer: syntax error" 

let rec exp (tl : token list) : exp * token list = 
  match tl with 
  | IF::t -> let (b1, t) = exp t in
      let (b2, t) = exp (verify THEN t) in
      let (b3, t) = exp (verify ELSE t) in
      (If(b1,b2,b3), t)
  | LET::VAR x::EQ::t -> let (b1, t) = exp t in
      let (b2, t) = exp (verify IN t) in
      (Let(x,b1,b2), t)
  | LET::REC::VAR f::VAR x::EQ::t ->  let (b1,t) = exp t in
      let (b2,t) = exp (verify IN t) in
      (Letrec (f,x,b1,b2),t)
  | LET::REC::VAR f::LP::VAR x::COL::t ->
      let (t1,t) = typer t in
      let (t2,t) = typer (verify COL (verify RP t)) in
      let (b1,t) = exp (verify EQ t) in
      let (b2,t) = exp (verify IN t) in
      (Letrecty (f,x,t1,t2,b1,b2), t)
  | LAM::VAR x::COL::TY t1::ARR::t -> let (b1,t) = exp t in (Lamty(x,t1,b1), t)
  | LAM::VAR x::ARR::t -> let (b1, t) = exp t in (Lam(x,b1), t)
  | t -> cexp t
and cexp (tl : token list) = let (b1,t) = sexp tl in cexp' b1 t
and cexp' b1 (t : token list) = match t with
  | LEQ::t -> let (b2,t) = sexp t in ( Oapp(Leq,b1,b2), t )
  | t -> (b1, t)
and sexp (tl : token list) = let (b1,t) = mexp tl in sexp' b1 t
and sexp' b1 (t : token list) = match t with
  | SUB::t -> let (b2,t) = mexp t in sexp' ( Oapp(Sub,b1,b2) ) t
  | ADD::t -> let (b2,t) = mexp t in sexp' ( Oapp(Add,b1,b2) ) t 
  | t -> (b1,t)
and mexp (tl : token list) = let (b1,t) = aexp tl in mexp' b1 t
and mexp' b1 (t : token list) = match t with
  | MUL::t -> let (b2,t) = aexp t in mexp' (Oapp(Mul,b1,b2)) t
  | t -> (b1,t)
and aexp (tl : token list) = let (b1,t) = pexp tl in aexp' b1 t
and aexp' b1 (t : token list) = match t with
  | CON _ :: _ | VAR _ :: _ | LP :: _  ->
      let (b2,t) = pexp t in aexp' (Fapp(b1,b2)) t
  | t -> (b1,t)
and pexp (tl : token list) = match tl with
  | CON (Bcon b)::t -> (Con (Bcon b), t)
  | CON (Icon n)::t -> (Con (Icon n), t)
  | VAR x::t -> (Var x, t)
  | LP::t -> let (b1,t) = exp t in (b1, verify RP t)
  | _ -> failwith "exp: unexpected token"
  
(* ------ TYPE CHECKER ------ *)

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
  match x1_ty, x2_ty, op with
  | Int, Int, Leq -> Bool
  | Int, Int, _ -> Int
  | _, _, _ -> failwith "check_oapp: operation is ill-typed"
and check_fapp fun_ty exp_ty =
  match fun_ty with
  | Arrow(Int,t2) -> if exp_ty = Int then fun_ty else failwith "check_fapp: expression has unexpected type"
  | Arrow(Bool,t2) -> if exp_ty = Bool then fun_ty else failwith "check_fapp: expression has unexpected type"
  | _ -> failwith "check_fapp: Illegal application (no function given)"
and check_if ex1_ty ex2_ty ex3_ty =
  if ex1_ty = Bool then
    if ex2_ty = ex3_ty then ex2_ty
    else failwith "check_if: 'if' is ill-typed"
  else failwith "check_if: 'if' condition has to be type bool"
    

(* ------ EVALUATION ------ *)

let rec eval env exp : value =
  match exp with
  | Var x -> lookup x env
  | Con(con) -> begin
      match con with
      | Bcon(b) -> Bval b
      | Icon(i) -> Ival i
    end
  | Oapp(op,ex1,ex2) -> eval_op op (eval env ex1) (eval env ex2)
  | Fapp(ex1,ex2) -> eval_fun (eval env ex1) (eval env ex2)
  | If(ex1,ex2,ex3) -> eval_if env (eval env ex1) ex2 ex3
  | Lam(x,exp) | Lamty(x,_,exp) -> Closure (x,exp,env)
  | Let(x,ex1,ex2) -> eval (update env x (eval env ex1)) ex2
  | Letrec(f,x,ex1,ex2) | Letrecty(f,x,_,_,ex1,ex2) -> eval (update env f (Bclosure (f,x,ex1,env))) ex2
and eval_op op v1 v2 = match op, v1, v2 with
  | Add, Ival(i1), Ival(i2) -> Ival (i1 + i2)
  | Sub, Ival(i1), Ival(i2) -> Ival (i1 - i2)
  | Mul, Ival(i1), Ival(i2) -> Ival (i1 * i2)
  | Leq, Ival(i1), Ival(i2) -> Bval (i1 <= i2)
  | _ -> failwith "eval_op: unexpected value"
and eval_fun v1 v2 = match v1 with
  | Closure (x,e,env) -> eval (update env x v2) e
  | Bclosure (f,x,e,env) -> eval (update (update env f v1) x v2) e
  | _ -> failwith "eval_fun: function does not take arguments"
and eval_if env v ex1 ex2 = match v with
  | Bval(true) -> eval env ex1
  | Bval(false) -> eval env ex2
  | _ -> failwith "eval_if: unexpected value"

(* ------ TOP-LEVEL COMMANDS ------ *)  

let env = empty ;;
  
let checkStr s = check env (fst(exp (skip(lex s) []))) ;;
let evalStr s = eval env (fst(exp (skip(lex s) []))) ;;
