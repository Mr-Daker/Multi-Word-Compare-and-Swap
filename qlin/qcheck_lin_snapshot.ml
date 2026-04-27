module Spec = struct
  type t = int Mcas_snapshot_volatile.t

  type cmd =
    | Update of int * int
    | Scan
    | Size

  let show_cmd = function
    | Update (i, v) -> Printf.sprintf "Update (%d, %d)" i v
    | Scan -> "Scan"
    | Size -> "Size"

  let gen_cmd =
    let open QCheck.Gen in
    oneof_weighted
      [
        (5, pair (0 -- 2) nat_small |> map (fun (i, v) -> Update (i, v)));
        (4, pure Scan);
        (1, pure Size);
      ]

  let shrink_cmd = QCheck.Shrink.nil

  type res =
    | RUnit
    | RArray of int array
    | RInt of int

  let show_res = function
    | RUnit -> "Unit"
    | RArray a ->
        let body =
          Array.to_list a |> List.map string_of_int |> String.concat "; "
        in
        Printf.sprintf "[|%s|]" body
    | RInt i -> Printf.sprintf "Int %d" i

  let equal_res a b =
    match (a, b) with
    | RUnit, RUnit -> true
    | RInt x, RInt y -> x = y
    | RArray x, RArray y -> Array.length x = Array.length y && Array.for_all2 ( = ) x y
    | _ -> false

  let init () = Mcas_snapshot_volatile.create 3 0
  let cleanup _ = ()

  let run cmd s =
    match cmd with
    | Update (i, v) ->
        Mcas_snapshot_volatile.update s i v;
        RUnit
    | Scan -> RArray (Mcas_snapshot_volatile.scan s)
    | Size -> RInt (Mcas_snapshot_volatile.size s)
end

module Test = Lin_domain.Make_internal (Spec)

let () =
  QCheck_base_runner.run_tests_main
    [
      Test.lin_test ~count:100 ~name:"mcas_snapshot_volatile_linearizable";
      Test.stress_test ~count:100 ~name:"mcas_snapshot_volatile_stress";
    ]
