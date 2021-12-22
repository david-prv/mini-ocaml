(* TYPE DECLARATIONS *)

type token = AT | BT | CT | LP | RP ;;

type ('a, 'b) env = ('a * 'b) list 
    
type var = string
type con = Bcon of bool | Icon of int
type op  = Add | Sub | Mul | Leq
type ty = Bool | Int | Arrow of ty * ty 
type exp = Var of var | Con of con
         | If of exp * exp * exp
         | Lam of var * exp 
         | Oapp of op * exp * exp
         | Fapp of exp * exp 
         | Let of var * exp * exp
         | Letrec of var * var * exp * exp
         | Lamty of var * ty * exp 
         | Letrecty of var * var * ty * ty * exp * exp
  
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

let rec type_checker env exp : ty = 
  match exp with
  | Con(con) -> begin
      match con with
      | Bcon(bool) -> Bool
      | Icon(int) -> Int 
    end
  | Var(var) -> lookup var env
  | Oapp(op,ex1,ex2) -> check_oapp op (type_checker env ex1) (type_checker env ex2)
  | Fapp(ex1,ex2) -> check_fapp (type_checker env ex1) (type_checker env ex2)
  | If(ex1,ex2,ex3) -> check_if (type_checker env ex1) (type_checker env ex2) (type_checker env ex3)
  | Lam(_,_) -> failwith "type_checker: missing lambda type"
  | Lamty(x,ty,ex) -> Arrow(ty, type_checker (update env x ty) ex)
  | Let(x,ex1,ex2) -> type_checker (update env x (type_checker env ex1)) ex2
  | Letrec(f,x,ex1,ex2) -> failwith "type_checker: missing let rec type"
  | Letrecty(f,x,ty1,ty2,ex1,ex2) -> Arrow(ty1, type_checker (update env f (Arrow(ty1, ty2))) ex2)
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

(* TOPLEVEL *)

let environment = empty
let exp = (Con(Icon 1))
let exp' = (Var "x")
let exp'' = (Oapp(Add, Con(Icon 1), Con(Icon 2)))
