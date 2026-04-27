module Spec = struct
  type t = int Stm_persistent.ref

  type cmd =
    | Get
    | Set of int
    | Txn of int * int
    | Recover

  let show_cmd = function
    | Get -> "Get"
    | Set v -> Printf.sprintf "Set %d" v
    | Txn (expected, desired) -> Printf.sprintf "Txn (%d -> %d)" expected desired
    | Recover -> "Recover"

  let gen_cmd =
    let open QCheck.Gen in
    oneof_weighted
      [
        (3, pure Get);
        (3, map (fun v -> Set v) nat_small);
        (3, pair nat_small nat_small |> map (fun (a, b) -> Txn (a, b)));
        (1, pure Recover);
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

  let init () = Stm_persistent.ref 0
  let cleanup _ = ()

  let run cmd r =
    match cmd with
    | Get -> RInt (Stm_persistent.get r)
    | Set v ->
        Stm_persistent.set r v;
        RUnit
    | Txn (expected, desired) ->
        RBool (Stm_persistent.commit [ Stm_persistent.make_op r ~expected ~desired ])
    | Recover ->
        Stm_persistent.recover ();
        RUnit
end

module Test = Lin_domain.Make_internal (Spec)

let () =
  QCheck_base_runner.run_tests_main
    [
      Test.lin_test ~count:200 ~name:"stm_persistent_linearizable";
      Test.stress_test ~count:200 ~name:"stm_persistent_stress";
    ]
