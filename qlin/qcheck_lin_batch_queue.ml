(** QCheck-Lin Linearizability Test for Batch Bounded Blocking Queue

    NOTE: This file is provided as a scaffold, but the project currently has
    no [BatchQueue] module in source, so it is not wired into qlin/dune yet.
    Once BatchQueue is added, include this executable in [qlin/dune].
*)

(***
module BQ = BatchQueue

module BatchQueueSig = struct
  type t = int BQ.t

  let init () = BQ.create 6
  let cleanup _ = ()

  open Lin
  let int_small = nat_small

  let try_enq1 q x = BQ.try_enq q [| x |]
  let try_enq2 q x y = BQ.try_enq q [| x; y |]
  let try_enq3 q x y z = BQ.try_enq q [| x; y; z |]

  let try_deq1 q = BQ.try_deq q 1
  let try_deq2 q = BQ.try_deq q 2
  let try_deq3 q = BQ.try_deq q 3

  let api = [
    val_ "try_enq1" try_enq1 (t @-> int_small @-> returning bool);
    val_ "try_enq2" try_enq2 (t @-> int_small @-> int_small @-> returning bool);
    val_ "try_enq3" try_enq3 (t @-> int_small @-> int_small @-> int_small @-> returning bool);
    val_ "try_deq1" try_deq1 (t @-> returning (option (array int_small)));
    val_ "try_deq2" try_deq2 (t @-> returning (option (array int_small)));
    val_ "try_deq3" try_deq3 (t @-> returning (option (array int_small)));
    val_ "size" BQ.size (t @-> returning int);
    val_ "capacity" BQ.capacity (t @-> returning int);
  ]
end

module BQ_domain = Lin_domain.Make(BatchQueueSig)

let () =
  QCheck_base_runner.run_tests_main [
    BQ_domain.lin_test ~count:1000 ~name:"Batch queue linearizability";
  ]
***)
