(** ThreadSanitizer stress test for Stm_volatile.

    Spawns [num_domains] domains that all hammer the same ref with
    concurrent Get / Set / commit (Txn) operations.  TSan will report
    any data races detected in the implementation. *)

let num_domains    = 4
let iterations     = 10_000

let () =
  let r = Stm_volatile.ref 0 in
  let domains =
    Array.init num_domains (fun id ->
      Domain.spawn (fun () ->
        for i = 0 to iterations - 1 do
          let v = (id * iterations + i) mod 100 in
          (match i mod 3 with
          | 0 -> ignore (Stm_volatile.get r)
          | 1 -> Stm_volatile.set r v
          | _ ->
            let current = Stm_volatile.get r in
            ignore (Stm_volatile.commit
              [ Stm_volatile.make_op r ~expected:current ~desired:v ])
          )
        done))
  in
  Array.iter Domain.join domains;
  Printf.printf "tsan_volatile: done (%d domains x %d iters)\n%!"
    num_domains iterations
