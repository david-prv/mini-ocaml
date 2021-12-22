(* TYPE DECLARATIONS *)

type token = AT | BT | CT | LP | RP
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
  | Let(x,ex1,ex2) -> eval (update env x (eval env ex2)) ex2
  | Letrec(f,x,ex1,ex2) | Letrecty(f,x,_,_,ex1,ex2) -> eval (update env f (Bclosure (f,x,ex1,env))) ex2
and eval_op op v1 v2 = match op, v1, v2 with
  | Add, Ival(i1), Ival(i2) -> Ival (i1 + i2)
  | Sub, Ival(i1), Ival(i2) -> Ival (i1 - i2)
  | Mul, Ival(i1), Ival(i2) -> Ival (i1 * i2)
  | Leq, Ival(i1), Ival(i2) -> Bval (i1 <= i2)
  | _ -> failwith "eval_op: unexpected value (maybe a closure?)"
and eval_fun env ex1 ex2 = let var = match ex2 with
    | Lam(x,_) | Lamty(x,_,_) -> x
    | Let(x,_,_) | Letrec(x,_,_,_) -> x
    | Letrecty(_,x,_,_,_,_) -> x
    | _ -> failwith "eval_fun: function does not take arguments"
  in eval (update env var (eval env ex1)) ex2
and eval_if env v ex1 ex2 = match v with
  | Bval(true) -> eval env ex1
  | Bval(false) -> eval env ex2
  | _ -> failwith "eval_if: unexpected value (maybe a closure?)"

(* TOPLEVEL *)

let environment = empty ;;
let exp = (Con(Icon 1)) ;;
let exp' = (Var "x") ;;
let exp'' = (Oapp(Add, Con(Icon 1), Con(Icon 2))) ;;
eval environment exp'' ;; (* yields Ival 3 *)
