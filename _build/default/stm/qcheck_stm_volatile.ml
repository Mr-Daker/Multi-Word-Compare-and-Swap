(** QCheck-STM State Machine Test for Stm_volatile

    Tests the volatile STM's single-ref interface against a sequential
    integer model using QCheck's State Machine Testing framework.

    == What is tested ==

    The SUT is a single [int Stm_volatile.ref].
    The model state is the [int] value that the ref should hold.

    Commands:
    - Get        : read the ref value
    - Set v      : unconditionally write v
    - Txn (e, d) : CAS-style commit; succeeds iff current value = e
*)

open QCheck
open STM

type cmd =
  | Get
  | Set of int
  | Txn of int * int

let show_cmd = function
  | Get -> "Get"
  | Set v -> Printf.sprintf "Set(%d)" v
  | Txn (e, d) -> Printf.sprintf "Txn(%d->%d)" e d

let arb_cmd _state =
  QCheck.make ~print:show_cmd
    Gen.(oneof [
      return Get;
      map (fun v -> Set v) small_int;
      map2 (fun e d -> Txn (e, d)) small_int small_int;
    ])

let next_state cmd state =
  match cmd with
  | Get -> state
  | Set v -> v
  | Txn (expected, desired) -> if state = expected then desired else state

let precond _cmd _state = true

let run cmd sut =
  match cmd with
  | Get ->
    Res (int, Stm_volatile.get sut)
  | Set v ->
    Stm_volatile.set sut v;
    Res (unit, ())
  | Txn (expected, desired) ->
    Res (bool, Stm_volatile.commit
      [ Stm_volatile.make_op sut ~expected ~desired ])

let postcond cmd state result =
  match cmd, result with
  | Get, Res ((Int, _), v) ->
    (v : int) = state
  | Set _, Res ((Unit, _), ()) ->
    true
  | Txn (expected, _desired), Res ((Bool, _), ok) ->
    (ok : bool) = (state = expected)
  | _ -> false

module Spec = struct
  type sut   = int Stm_volatile.ref
  type state = int
  type nonrec cmd = cmd

  let arb_cmd  = arb_cmd
  let show_cmd = show_cmd
  let init_state = 0
  let next_state = next_state
  let precond    = precond
  let run        = run
  let init_sut () = Stm_volatile.ref 0
  let cleanup  _  = ()
  let postcond   = postcond
end

module Seq = STM_sequential.Make(Spec)
module Dom = STM_domain.Make(Spec)

let run_sequential_test () =
  Printf.printf "Running sequential STM test for stm_volatile...\n\n%!";
  let t = Seq.agree_test ~count:1000 ~name:"stm_volatile sequential" in
  QCheck_base_runner.run_tests ~verbose:true [t]

let run_concurrent_test () =
  Printf.printf "Running concurrent STM test for stm_volatile...\n\n%!";
  let arb_cmds_par =
    Dom.arb_triple 15 10 Spec.arb_cmd Spec.arb_cmd Spec.arb_cmd
  in
  let t =
    QCheck.Test.make ~retries:10 ~count:200
      ~name:"stm_volatile concurrent"
      arb_cmds_par
    @@ fun triple -> Dom.agree_prop_par triple
  in
  QCheck_base_runner.run_tests ~verbose:true [t]

let () =
  let name = if Array.length Sys.argv > 1 then Sys.argv.(1) else "sequential" in
  match name with
  | "sequential" | "seq"  -> ignore (run_sequential_test ())
  | "concurrent" | "conc" -> ignore (run_concurrent_test ())
  | _ ->
    Printf.eprintf "Usage: %s [sequential|concurrent]\n" Sys.argv.(0);
    exit 1
