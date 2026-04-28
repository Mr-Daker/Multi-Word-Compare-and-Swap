(** Lock-free sorted linked-list set using MCAS to couple validation and updates. *)

type node = {
  key : int;
  next : node option Mcas_volatile.ref;
  deleted : bool Mcas_volatile.ref;
}

type t = {
  head : node;
}

let min_key = Int.min_int
let max_key = Int.max_int

let create () =
  let tail =
    {
      key = max_key;
      next = Mcas_volatile.ref None;
      deleted = Mcas_volatile.ref false;
    }
  in
  let head =
    {
      key = min_key;
      next = Mcas_volatile.ref (Some tail);
      deleted = Mcas_volatile.ref false;
    }
  in
  { head }

let cas_next node ~expected ~desired =
  Mcas_volatile.make_cas node.next ~expected ~desired

let cas_deleted node ~expected ~desired =
  Mcas_volatile.make_cas node.deleted ~expected ~desired

let find_window t key =
  let rec restart () =
    let rec loop pred curr_link =
      match curr_link with
      | None -> assert false
      | Some curr ->
          let succ = Mcas_volatile.get curr.next in
          if Mcas_volatile.get curr.deleted then
            if Mcas_volatile.mcas [ cas_next pred ~expected:curr_link ~desired:succ ] then
              loop pred succ
            else
              restart ()
          else if curr.key >= key then
            (pred, curr_link, succ)
          else
            loop curr succ
    in
    loop t.head (Mcas_volatile.get t.head.next)
  in
  restart ()

let rec insert t key =
  if key = min_key || key = max_key then
    invalid_arg "Mcas_lockfree_linked_list.insert: sentinel key is reserved";
  let pred, curr_link, _ = find_window t key in
  match curr_link with
  | Some curr when curr.key = key -> false
  | _ ->
      let node =
        {
          key;
          next = Mcas_volatile.ref curr_link;
          deleted = Mcas_volatile.ref false;
        }
      in
      let ops =
        [
          cas_next pred ~expected:curr_link ~desired:(Some node);
          cas_deleted pred ~expected:false ~desired:false;
          (match curr_link with
          | Some curr -> cas_deleted curr ~expected:false ~desired:false
          | None -> assert false);
        ]
      in
      if Mcas_volatile.mcas ops then true else insert t key

let rec delete t key =
  if key = min_key || key = max_key then false
  else
    let pred, curr_link, succ = find_window t key in
    match curr_link with
    | Some curr when curr.key = key ->
        let ops =
          [
            cas_next pred ~expected:curr_link ~desired:succ;
            cas_deleted pred ~expected:false ~desired:false;
            cas_deleted curr ~expected:false ~desired:true;
          ]
        in
        if Mcas_volatile.mcas ops then true
        else if Mcas_volatile.get curr.deleted then false
        else delete t key
    | _ -> false

let member t key =
  if key = min_key || key = max_key then false
  else
    let _, curr_link, _ = find_window t key in
    match curr_link with
    | Some curr -> curr.key = key && not (Mcas_volatile.get curr.deleted)
    | None -> false

let to_list t =
  let rec loop acc = function
    | None -> List.rev acc
    | Some node ->
        let next = Mcas_volatile.get node.next in
        if node.key = max_key then
          List.rev acc
        else if Mcas_volatile.get node.deleted then
          loop acc next
        else
          loop (node.key :: acc) next
  in
  loop [] (Mcas_volatile.get t.head.next)
