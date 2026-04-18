(** ThreadSanitizer stress test for Stm_persistent.

    Spawns [num_domains] domains that concurrently Get / Set / commit
    and occasionally call recover () on the same persistent ref.
    TSan will report any data races detected in the implementation. *)

let num_domains = 4
let iterations  = 10_000

let () =
  let r = Stm_persistent.ref 0 in
  let domains =
    Array.init num_domains (fun id ->
      Domain.spawn (fun () ->
        for i = 0 to iterations - 1 do
          let v = (id * iterations + i) mod 100 in
          (match i mod 4 with
          | 0 -> ignore (Stm_persistent.get r)
          | 1 -> Stm_persistent.set r v
          | 2 ->
            let current = Stm_persistent.get r in
            ignore (Stm_persistent.commit
              [ Stm_persistent.make_op r ~expected:current ~desired:v ])
          | _ -> Stm_persistent.recover ()
          )
        done))
  in
  Array.iter Domain.join domains;
  Printf.printf "tsan_persistent: done (%d domains x %d iters)\n%!"
    num_domains iterations
