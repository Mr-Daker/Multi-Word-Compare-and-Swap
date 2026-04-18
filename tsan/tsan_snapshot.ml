(** ThreadSanitizer stress test for Stm_snapshot.

    Spawns [num_domains] domains that concurrently call update and scan
    on the same snapshot object.  TSan will report any data races
    detected in the implementation. *)

let num_domains    = 4
let snapshot_size  = 3
let iterations     = 10_000

let () =
  let s = Stm_snapshot.create snapshot_size 0 in
  let domains =
    Array.init num_domains (fun id ->
      Domain.spawn (fun () ->
        for i = 0 to iterations - 1 do
          let idx = (id + i) mod snapshot_size in
          let v   = (id * iterations + i) mod 100 in
          if i mod 3 = 0 then
            ignore (Stm_snapshot.scan s)
          else
            Stm_snapshot.update s idx v
        done))
  in
  Array.iter Domain.join domains;
  Printf.printf "tsan_snapshot: done (%d domains x %d iters)\n%!"
    num_domains iterations
