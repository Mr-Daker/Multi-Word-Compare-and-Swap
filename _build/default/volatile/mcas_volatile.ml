(** Multi-Word Compare-and-Swap (MCAS) for volatile memory.
    This follows the high-level algorithm from Guerraoui et al.,
    "Efficient Multi-word Compare and Swap" (DISC 2020). *)

type status =
  | Active
  | Successful
  | Failed

type state =
  | Value of Obj.t
  | Word of word_desc

and word_desc = {
  address : cell;
  old_value : Obj.t;
  new_value : Obj.t;
  parent : mcas_desc;
}

and mcas_desc = {
  status : status Atomic.t;
  mutable words : word_desc array;
  retired : bool Atomic.t;
}

and cell = state Atomic.t

type 'a ref = {
  id : int;
  cell : cell;
}

type cas_op =
  | CAS : 'a ref * 'a * 'a -> cas_op

let next_id = Atomic.make 0

let fresh_id () =
  let rec loop () =
    let cur = Atomic.get next_id in
    if Atomic.compare_and_set next_id cur (cur + 1) then cur else loop ()
  in
  loop ()

let ref v = { id = fresh_id (); cell = Atomic.make (Value (Obj.repr v)) }

let set r v = Atomic.set r.cell (Value (Obj.repr v))

let same_obj a b = a == b

let same_desc a b = a == b

let state_points_to_word state wd =
  match state with
  | Word wd' -> wd' == wd
  | Value _ -> false

let is_successful desc =
  match Atomic.get desc.status with
  | Successful -> true
  | Active | Failed -> false

let logical_value wd =
  if is_successful wd.parent then wd.new_value else wd.old_value

let retire_for_cleanup desc =
  ignore (Atomic.compare_and_set desc.retired false true)

let rec read_internal addr self =
  let content = Atomic.get addr in
  match content with
  | Value value -> (content, value)
  | Word wd ->
      let parent = wd.parent in
      if (match self with Some self_desc -> not (same_desc self_desc parent) | None -> true)
         && Atomic.get parent.status = Active
      then (
        ignore (mcas_desc parent);
        read_internal addr self)
      else
        (content, logical_value wd)

and acquire_word desc wd =
  let rec retry () =
    let content, value = read_internal wd.address (Some desc) in
    if state_points_to_word content wd then
      true
    else if not (same_obj value wd.old_value) then
      false
    else if Atomic.get desc.status <> Active then
      false
    else if Atomic.compare_and_set wd.address content (Word wd) then
      true
    else
      retry ()
  in
  retry ()

and mcas_desc desc =
  let success = Stdlib.ref true in
  let i = Stdlib.ref 0 in
  while !success && !i < Array.length desc.words do
    if not (acquire_word desc desc.words.(!i)) then success := false;
    Stdlib.incr i
  done;
  let final_status = if !success then Successful else Failed in
  if Atomic.compare_and_set desc.status Active final_status then retire_for_cleanup desc;
  is_successful desc

let get r =
  let _, value = read_internal r.cell None in
  Obj.obj value

let make_cas r ~expected ~desired = CAS (r, expected, desired)

let sort_ops ops =
  let compare_op (CAS (r1, _, _)) (CAS (r2, _, _)) = Int.compare r1.id r2.id in
  List.sort compare_op ops

let validate_distinct ops =
  let rec loop = function
    | CAS (r1, _, _) :: (CAS (r2, _, _) :: _ as rest) ->
        if r1.id = r2.id then
          invalid_arg "MCAS_Volatile.mcas: duplicate target reference"
        else
          loop rest
    | _ -> ()
  in
  loop ops

let build_descriptor ops =
  let ops = sort_ops ops in
  validate_distinct ops;
  let desc = { status = Atomic.make Active; words = [||]; retired = Atomic.make false } in
  let words =
    Array.of_list
      (List.map
         (fun (CAS (r, expected, desired)) ->
           {
             address = r.cell;
             old_value = Obj.repr expected;
             new_value = Obj.repr desired;
             parent = desc;
           })
         ops)
  in
  desc.words <- words;
  desc

let mcas ops =
  let desc = build_descriptor ops in
  mcas_desc desc
