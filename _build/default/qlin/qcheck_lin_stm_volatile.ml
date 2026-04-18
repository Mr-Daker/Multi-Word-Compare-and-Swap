module Spec = struct
  type t = int Stm_volatile.ref

  type cmd =
    | Get
    | Set of int
    | Txn of int * int

  let show_cmd = function
    | Get -> "Get"
    | Set v -> Printf.sprintf "Set %d" v
    | Txn (expected, desired) -> Printf.sprintf "Txn (%d -> %d)" expected desired

  let gen_cmd =
    let open QCheck.Gen in
    frequency
      [
        (3, pure Get);
        (3, map (fun v -> Set v) small_int);
        (4, pair small_int small_int |> map (fun (a, b) -> Txn (a, b)));
      ]

  let shrink_cmd = QCheck.Shrink.nil

  type res =
    | RInt of int
    | RBool of bool
    | RUnit

  let show_res = function
    | RInt v -> Printf.sprintf "Int %d" v
    | RBool b -> Printf.sprintf "Bool %b" b
    | RUnit -> "Unit"

  let equal_res a b =
    match (a, b) with
    | RInt x, RInt y -> x = y
    | RBool x, RBool y -> Bool.equal x y
    | RUnit, RUnit -> true
    | _ -> false

  let init () = Stm_volatile.ref 0
  let cleanup _ = ()

  let run cmd r =
    match cmd with
    | Get -> RInt (Stm_volatile.get r)
    | Set v ->
        Stm_volatile.set r v;
        RUnit
    | Txn (expected, desired) ->
        RBool (Stm_volatile.commit [ Stm_volatile.make_op r ~expected ~desired ])
end

module Test = Lin_domain.Make_internal (Spec)

let () =
  QCheck_base_runner.run_tests_main
    [
      Test.lin_test ~count:200 ~name:"stm_volatile_linearizable";
      Test.stress_test ~count:200 ~name:"stm_volatile_stress";
    ]
