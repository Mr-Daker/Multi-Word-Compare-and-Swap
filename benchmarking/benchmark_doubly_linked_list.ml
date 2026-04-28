let printf = Printf.printf

type scenario = {
  name : string;
  insert_percent : int;
  delete_percent : int;
}

type result = {
  impl_name : string;
  scenario_name : string;
  domains : int;
  total_ops : int;
  seconds : float;
  avg_us_per_op : float;
}

let scenarios =
  [
    { name = "search_100"; insert_percent = 0; delete_percent = 0 };
    { name = "balanced_34_33_33"; insert_percent = 34; delete_percent = 33 };
    { name = "update_heavy_45_45_10"; insert_percent = 45; delete_percent = 45 };
  ]

let domain_counts = [ 2; 4; 8; 16; 32 ]
let ops_per_domain = 150_000
let key_space = 256
let initial_keys = 128

let flush () = Stdlib.flush Stdlib.stdout

let prefill set insert =
  for key = 0 to initial_keys - 1 do
    ignore (insert set key)
  done

let run_workload
    (type a)
    ~(impl_name : string)
    ~(create : unit -> a)
    ~(insert : a -> int -> bool)
    ~(delete : a -> int -> bool)
    ~(member : a -> int -> bool)
    ~(domains : int)
    ~(scenario : scenario) =
  let set = create () in
  prefill set insert;
  let start = Unix.gettimeofday () in
  let workers =
    List.init domains (fun domain_id ->
        Domain.spawn (fun () ->
            let seed =
              Random.State.make [| 0x51A7 + domain_id; scenario.insert_percent; scenario.delete_percent |]
            in
            for _ = 1 to ops_per_domain do
              let key = Random.State.int seed key_space in
              let choice = Random.State.int seed 100 in
              if choice < scenario.insert_percent then
                ignore (insert set key)
              else if choice < scenario.insert_percent + scenario.delete_percent then
                ignore (delete set key)
              else
                ignore (member set key)
            done))
  in
  List.iter Domain.join workers;
  let seconds = Unix.gettimeofday () -. start in
  let total_ops = domains * ops_per_domain in
  {
    impl_name;
    scenario_name = scenario.name;
    domains;
    total_ops;
    seconds;
    avg_us_per_op = (seconds *. 1_000_000.0) /. float_of_int total_ops;
  }

let print_result result =
  printf
    "%-32s %-24s domains=%d  ops=%8d  time=%9.6fs  avg=%8.3fus/op\n"
    result.impl_name result.scenario_name result.domains result.total_ops result.seconds
    result.avg_us_per_op;
  flush ()

let print_header () =
  printf "\nDoubly Linked-List Benchmark Comparison (Elapsed Time)\n";
  printf "initial_keys=%d  key_space=%d  ops/domain=%d\n\n" initial_keys key_space ops_per_domain;
  flush ()

let benchmark_impl
    (type a)
    ~(impl_name : string)
    ~(create : unit -> a)
    ~(insert : a -> int -> bool)
    ~(delete : a -> int -> bool)
    ~(member : a -> int -> bool) =
  List.concat_map
    (fun scenario ->
      List.map
        (fun domains ->
          printf "running %-32s %-24s domains=%d\n" impl_name scenario.name domains;
          flush ();
          let result =
            run_workload ~impl_name ~create ~insert ~delete ~member ~domains ~scenario
          in
          print_result result;
          result)
        domain_counts)
    scenarios

let print_summary_group results =
  let grouped =
    List.sort
      (fun a b ->
        match String.compare a.scenario_name b.scenario_name with
        | 0 -> compare a.domains b.domains
        | c -> c)
      results
  in
  printf "\nSummary By Scenario\n";
  List.iter print_result grouped

let () =
  print_header ();
  let coarse_results =
    benchmark_impl ~impl_name:"coarse_doubly_linked_list"
      ~create:Coarse_doubly_linked_list.create ~insert:Coarse_doubly_linked_list.insert
      ~delete:Coarse_doubly_linked_list.delete ~member:Coarse_doubly_linked_list.member
  in
  let mcas_results =
    benchmark_impl ~impl_name:"mcas_doubly_linked_list"
      ~create:Mcas_doubly_linked_list.create
      ~insert:Mcas_doubly_linked_list.insert
      ~delete:Mcas_doubly_linked_list.delete
      ~member:Mcas_doubly_linked_list.member
  in
  print_summary_group (coarse_results @ mcas_results)
