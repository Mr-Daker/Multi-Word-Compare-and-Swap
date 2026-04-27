let printf = Printf.printf

type scenario = {
  name : string;
  update_percent : int;
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
    { name = "updates_100"; update_percent = 100 };
    { name = "balanced_50_50"; update_percent = 50 };
    { name = "scans_90"; update_percent = 10 };
    { name = "scans_100"; update_percent = 0 };
  ]

let domain_counts = [ 2; 4; 8; 16; 32;]

let registers = 16
let ops_per_domain = 200_000

let flush () = Stdlib.flush Stdlib.stdout

let run_workload
    (type a)
    ~(impl_name : string)
    ~(create : int -> int -> a)
    ~(update : a -> int -> int -> unit)
    ~(scan : a -> int array)
    ~(domains : int)
    ~(scenario : scenario) =
  let snapshot = create registers 0 in
  let start = Unix.gettimeofday () in
  let workers =
    List.init domains (fun domain_id ->
        Domain.spawn (fun () ->
            let seed = Random.State.make [| 0xC0FFEE + domain_id; scenario.update_percent |] in
            for iter = 1 to ops_per_domain do
              let slot = Random.State.int seed registers in
              let choice = Random.State.int seed 100 in
              if choice < scenario.update_percent then
                update snapshot slot (domain_id * ops_per_domain + iter)
              else
                ignore (scan snapshot)
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
    "%-22s %-16s domains=%d  ops=%8d  time=%9.6fs  avg=%8.3fus/op\n"
    result.impl_name result.scenario_name result.domains result.total_ops result.seconds
    result.avg_us_per_op;
  flush ()

let print_header () =
  printf "\nSnapshot Benchmark Comparison (Elapsed Time)\n";
  printf "registers=%d  ops/domain=%d\n\n" registers ops_per_domain;
  flush ()

let benchmark_impl
    (type a)
    ~(impl_name : string)
    ~(create : int -> int -> a)
    ~(update : a -> int -> int -> unit)
    ~(scan : a -> int array) =
  List.concat_map
    (fun scenario ->
      List.map
        (fun domains ->
          printf "running %-22s %-16s domains=%d\n" impl_name scenario.name domains;
          flush ();
          let result =
            run_workload ~impl_name ~create ~update ~scan ~domains ~scenario
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
  let baseline_results =
    benchmark_impl ~impl_name:"snapshot_baseline" ~create:Snapshot.create
      ~update:Snapshot.update ~scan:Snapshot.scan
  in
  let volatile_results =
    benchmark_impl ~impl_name:"mcas_volatile" ~create:Mcas_snapshot_volatile.create
      ~update:Mcas_snapshot_volatile.update ~scan:Mcas_snapshot_volatile.scan
  in
  let all_results = baseline_results @ volatile_results in
  print_summary_group all_results
