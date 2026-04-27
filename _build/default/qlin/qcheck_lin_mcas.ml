module Spec = struct
  type t = int Mcas_volatile.ref

  type cmd =
    | Get
    | Set of int
    | Cas of int * int

  let show_cmd = function
    | Get -> "Get"
    | Set v -> Printf.sprintf "Set %d" v
    | Cas (expected, desired) -> Printf.sprintf "Cas (%d -> %d)" expected desired

  let gen_cmd =
    let open QCheck.Gen in
    oneof_weighted
      [
        (3, pure Get);
        (3, map (fun v -> Set v) nat_small);
        (4, pair nat_small nat_small |> map (fun (a, b) -> Cas (a, b)));
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

  let init () = Mcas_volatile.ref 0
  let cleanup _ = ()

  let run cmd r =
    match cmd with
    | Get -> RInt (Mcas_volatile.get r)
    | Set v ->
        Mcas_volatile.set r v;
        RUnit
    | Cas (expected, desired) ->
        RBool (Mcas_volatile.mcas [ Mcas_volatile.make_cas r ~expected ~desired ])
end

module Test = Lin_domain.Make_internal (Spec)

let () =
  QCheck_base_runner.run_tests_main
    [
      Test.lin_test ~count:200 ~name:"mcas_volatile_linearizable";
      Test.stress_test ~count:200 ~name:"mcas_volatile_stress";
    ]
