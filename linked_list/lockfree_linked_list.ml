(** Lock-free sorted linked-list set using marked next pointers and single-word CAS. *)

type link =
  | Alive of node option
  | Marked of node option

and node = {
  key : int;
  next : link Atomic.t;
}

type t = {
  head : node;
}

let min_key = Int.min_int
let max_key = Int.max_int

let create () =
  let tail = { key = max_key; next = Atomic.make (Alive None) } in
  let head = { key = min_key; next = Atomic.make (Alive (Some tail)) } in
  { head }

let is_marked node =
  match Atomic.get node.next with
  | Marked _ -> true
  | Alive _ -> false

let successor node =
  match Atomic.get node.next with
  | Alive next | Marked next -> next

let find_window t key =
  let rec restart () =
    let rec loop pred pred_state =
      match pred_state with
      | Marked _ -> restart ()
      | Alive curr_link -> (
          match curr_link with
          | None -> assert false
          | Some curr ->
              let curr_state = Atomic.get curr.next in
              match curr_state with
          | Marked succ ->
              if Atomic.compare_and_set pred.next pred_state (Alive succ) then
                loop pred (Alive succ)
              else
                restart ()
          | Alive succ ->
              if curr.key >= key then
                (pred, pred_state, curr_link, curr_state, succ)
              else
                loop curr curr_state)
    in
    loop t.head (Atomic.get t.head.next)
  in
  restart ()

let rec insert t key =
  if key = min_key || key = max_key then
    invalid_arg "Lockfree_linked_list.insert: sentinel key is reserved";
  let pred, pred_state, curr_link, _, _ = find_window t key in
  match curr_link with
  | Some curr when curr.key = key -> false
  | _ ->
      let node = { key; next = Atomic.make (Alive curr_link) } in
      if Atomic.compare_and_set pred.next pred_state (Alive (Some node)) then
        true
      else
        insert t key

let rec delete t key =
  if key = min_key || key = max_key then false
  else
    let pred, pred_state, curr_link, curr_state, succ = find_window t key in
    match curr_link with
    | Some curr when curr.key = key ->
        if Atomic.compare_and_set curr.next curr_state (Marked succ) then (
          ignore (Atomic.compare_and_set pred.next pred_state (Alive succ));
          true)
        else
          delete t key
    | _ -> false

let member t key =
  if key = min_key || key = max_key then false
  else
    let rec loop = function
      | None -> false
      | Some node ->
          if node.key >= key then
            node.key = key && not (is_marked node)
          else
            loop (successor node)
    in
    match Atomic.get t.head.next with
    | Alive first -> loop first
    | Marked _ -> assert false

let to_list t =
  let rec loop acc = function
    | None -> List.rev acc
    | Some node ->
        if node.key = max_key then
          List.rev acc
        else
          let next = successor node in
          if is_marked node then
            loop acc next
          else
            loop (node.key :: acc) next
  in
  match Atomic.get t.head.next with
  | Alive first -> loop [] first
  | Marked _ -> assert false
