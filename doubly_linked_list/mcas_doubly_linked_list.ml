module Mcas = Mcas_volatile

type node = {
  key : int;
  prev : node option Mcas.ref;
  next : node option Mcas.ref;
  deleted : bool Mcas.ref;
}

type t = {
  head : node;
}

let min_key = Int.min_int
let max_key = Int.max_int

let create () =
  let tail = { key = max_key; prev = Mcas.ref None; next = Mcas.ref None; deleted = Mcas.ref false } in
  let head = { key = min_key; prev = Mcas.ref None; next = Mcas.ref (Some tail); deleted = Mcas.ref false } in
  Mcas.set tail.prev (Some head);
  { head }

let cas_next node ~expected ~desired =
  Mcas.make_cas node.next ~expected ~desired

let cas_prev node ~expected ~desired =
  Mcas.make_cas node.prev ~expected ~desired

let cas_deleted node ~expected ~desired =
  Mcas.make_cas node.deleted ~expected ~desired

let find_window t key =
  let rec restart () =
    let rec loop curr_link =
      match curr_link with
      | None -> assert false
      | Some curr ->
          if Mcas.get curr.deleted then restart ()
          else if curr.key >= key then curr_link
          else loop (Mcas.get curr.next)
    in
    loop (Some t.head)
  in
  restart ()

let rec insert t key =
  if key = min_key || key = max_key then invalid_arg "Mcas_doubly_linked_list.insert: sentinel key is reserved";
  let curr_link = find_window t key in
  match curr_link with
  | Some curr when curr.key = key -> false
  | Some curr ->
      let prev_link = Mcas.get curr.prev in
      (match prev_link with
      | None -> insert t key
      | Some prev ->
          let node = {
            key;
            prev = Mcas.ref prev_link;
            next = Mcas.ref curr_link;
            deleted = Mcas.ref false;
          } in
          let node_link = Some node in
          let ops = [
            cas_next prev ~expected:curr_link ~desired:node_link;
            cas_prev curr ~expected:prev_link ~desired:node_link;
            cas_deleted prev ~expected:false ~desired:false;
            cas_deleted curr ~expected:false ~desired:false;
          ] in
          if Mcas.mcas ops then true
          else insert t key)
  | None -> false

let rec delete t key =
  if key = min_key || key = max_key then false
  else
    let curr_link = find_window t key in
    match curr_link with
    | Some curr when curr.key = key ->
        let prev_link = Mcas.get curr.prev in
        let next_link = Mcas.get curr.next in
        (match prev_link, next_link with
        | Some prev, Some next ->
            let ops = [
              cas_next prev ~expected:curr_link ~desired:next_link;
              cas_prev next ~expected:curr_link ~desired:prev_link;
              cas_deleted curr ~expected:false ~desired:true;
              cas_deleted prev ~expected:false ~desired:false;
              cas_deleted next ~expected:false ~desired:false;
            ] in
            if Mcas.mcas ops then true
            else delete t key
        | _ -> delete t key)
    | _ -> false

let member t key =
  if key = min_key || key = max_key then false
  else
    let curr_link = find_window t key in
    match curr_link with
    | Some curr -> curr.key = key && not (Mcas.get curr.deleted)
    | None -> false
