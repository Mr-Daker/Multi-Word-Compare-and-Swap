(** QCheck-STM State Machine Test for Stm_snapshot

    Tests the snapshot module's update/scan/size interface against a
    sequential integer-array model using QCheck's State Machine Testing
    framework.

    == What is tested ==

    The SUT is an [int Stm_snapshot.t] of fixed size [snapshot_size].
    The model state is an [int array] representing the expected contents.

    Commands:
    - Update (i, v) : write value v at index i
    - Scan           : atomically read all slots; must match model
    - Size           : return the number of slots
*)

open QCheck
open STM

let snapshot_size = 3

type cmd =
  | Update of int * int
  | Scan
  | Size

let show_cmd = function
  | Update (i, v) -> Printf.sprintf "Update(%d, %d)" i v
  | Scan           -> "Scan"
  | Size           -> "Size"

let arb_cmd _state =
  QCheck.make ~print:show_cmd
    Gen.(oneof [
      map2 (fun i v -> Update (i, v))
        (int_range 0 (snapshot_size - 1))
        small_int;
      return Scan;
      return Size;
    ])

(* Model state is an int array of length [snapshot_size]. *)
let next_state cmd state =
  match cmd with
  | Update (i, v) ->
    let s = Array.copy state in
    s.(i) <- v;
    s
  | Scan | Size -> state

let precond _cmd _state = true

let run cmd sut =
  match cmd with
  | Update (i, v) ->
    Stm_snapshot.update sut i v;
    Res (unit, ())
  | Scan ->
    Res (array int, Stm_snapshot.scan sut)
  | Size ->
    Res (int, Stm_snapshot.size sut)

let postcond cmd state result =
  match cmd, result with
  | Update _, Res ((Unit, _), ()) ->
    true
  | Scan, Res ((Array Int, _), got) ->
    let got : int array = got in
    Array.length got = Array.length state &&
    Array.for_all2 ( = ) got state
  | Size, Res ((Int, _), n) ->
    (n : int) = snapshot_size
  | _ -> false

module Spec = struct
  type sut   = int Stm_snapshot.t
  type state = int array
  type nonrec cmd = cmd

  let arb_cmd  = arb_cmd
  let show_cmd = show_cmd
  let init_state = Array.make snapshot_size 0
  let next_state = next_state
  let precond    = precond
  let run        = run
  let init_sut () = Stm_snapshot.create snapshot_size 0
  let cleanup  _  = ()
  let postcond   = postcond
end

module Seq = STM_sequential.Make(Spec)
module Dom = STM_domain.Make(Spec)

let run_sequential_test () =
  Printf.printf "Running sequential STM test for stm_snapshot...\n\n%!";
  let t = Seq.agree_test ~count:1000 ~name:"stm_snapshot sequential" in
  QCheck_base_runner.run_tests ~verbose:true [t]

let run_concurrent_test () =
  Printf.printf "Running concurrent STM test for stm_snapshot...\n\n%!";
  let arb_cmds_par =
    Dom.arb_triple 15 10 Spec.arb_cmd Spec.arb_cmd Spec.arb_cmd
  in
  let t =
    QCheck.Test.make ~retries:10 ~count:200
      ~name:"stm_snapshot concurrent"
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
