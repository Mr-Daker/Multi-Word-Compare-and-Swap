module Spec = struct
  type t = Mcas_lockfree_linked_list.t

  type cmd =
    | Insert of int
    | Delete of int
    | Member of int

  let show_cmd = function
    | Insert k -> Printf.sprintf "Insert %d" k
    | Delete k -> Printf.sprintf "Delete %d" k
    | Member k -> Printf.sprintf "Member %d" k

  let gen_cmd =
    let open QCheck.Gen in
    let gen_key = 0 -- 15 in
    oneof_weighted
      [
        (4, map (fun k -> Insert k) gen_key);
        (3, map (fun k -> Delete k) gen_key);
        (5, map (fun k -> Member k) gen_key);
      ]

  let shrink_cmd = QCheck.Shrink.nil

  type res =
    | RBool of bool

  let show_res = function
    | RBool b -> Printf.sprintf "Bool %b" b

  let equal_res a b =
    match (a, b) with
    | RBool x, RBool y -> Bool.equal x y

  let init () = Mcas_lockfree_linked_list.create ()
  let cleanup _ = ()

  let run cmd t =
    match cmd with
    | Insert k -> RBool (Mcas_lockfree_linked_list.insert t k)
    | Delete k -> RBool (Mcas_lockfree_linked_list.delete t k)
    | Member k -> RBool (Mcas_lockfree_linked_list.member t k)
end

module Test = Lin_domain.Make_internal (Spec)

let () =
  let arb = Test.arb_cmds_triple 3 2 in
  QCheck_base_runner.run_tests_main
    [
      QCheck.Test.make ~count:10 ~retries:1 ~name:"mcas_lockfree_linked_list_linearizable"
        arb Test.lin_prop;
      QCheck.Test.make ~count:10 ~retries:1 ~name:"mcas_lockfree_linked_list_stress"
        arb Test.stress_prop;
    ]
