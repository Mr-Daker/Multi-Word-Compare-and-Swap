(** Simple STM-style atomic multi-update interface for volatile memory.
    This is a coarse-grained transactional model using a single global lock. *)

type 'a ref = 'a Atomic.t

type txn_op =
  | Op : 'a ref * 'a * 'a -> txn_op

let global_lock = Mutex.create ()

let ref = Atomic.make
let get = Atomic.get
let set = Atomic.set

let make_op r ~expected ~desired = Op (r, expected, desired)

let commit ops =
  Mutex.lock global_lock;
  Fun.protect
    ~finally:(fun () -> Mutex.unlock global_lock)
    (fun () ->
      let ok =
        List.for_all
          (fun (Op (r, expected, _)) -> Atomic.get r == expected)
          ops
      in
      if ok then
        List.iter (fun (Op (r, _, desired)) -> Atomic.set r desired) ops;
      ok)
