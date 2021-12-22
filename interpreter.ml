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
  let check_operation operation x1 x2 =
    match operation with
    | Add -> if (x1 = Int) && (x2 = Int) then Arrow(Int,Arrow(Int,Int)) else failwith "check_op: Add is ill-typed"
    | Sub -> if (x1 = Int) && (x2 = Int) then Arrow(Int,Arrow(Int,Int)) else failwith "check_op: Sub is ill-typed"
    | Mul -> if (x1 = Int) && (x2 = Int) then Arrow(Int,Arrow(Int,Int)) else failwith "check_op: Mul is ill-typed"
    | Leq -> if (x1 = Int) && (x2 = Int) then Arrow(Int,Arrow(Int,Int)) else failwith "check_op: Leq is ill-typed"
  in
  match exp with
  | Con(con) -> begin
      match con with
      | Bcon(bool) -> Bool
      | Icon(int) -> Int 
    end
  | Var(var) -> lookup var env
  | Oapp(op,ex1,ex2) -> check_operation op (type_checker env ex1) (type_checker env ex2)
  | _ -> failwith "test" 

(* EVALUATION *)

(* TOPLEVEL *)

let environment = empty
let exp = (Con(Icon 1))
let exp' = (Var "x")
let exp'' = (Oapp(Add, Con(Icon 1), Con(Icon 2)))
