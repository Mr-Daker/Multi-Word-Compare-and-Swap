let min_key = Int.min_int
let max_key = Int.max_int

type node = {
  key : int;
  mutable prev : node option;
  mutable next : node option;
}

type t = {
  mutex : Mutex.t;
  head : node;
  tail : node;
}

let create () =
  let head = { key = min_key; prev = None; next = None } in
  let tail = { key = max_key; prev = Some head; next = None } in
  head.next <- Some tail;
  { mutex = Mutex.create (); head; tail }

let insert t key =
  if key = min_key || key = max_key then invalid_arg "Coarse_doubly_linked_list.insert: sentinel key is reserved";
  Mutex.lock t.mutex;
  let rec find_pos curr =
    match curr with
    | None -> assert false
    | Some n ->
        if n.key = key then (
          Mutex.unlock t.mutex;
          false
        ) else if n.key > key then (
          let prev_node = Option.get n.prev in
          let new_node = { key; prev = Some prev_node; next = Some n } in
          prev_node.next <- Some new_node;
          n.prev <- Some new_node;
          Mutex.unlock t.mutex;
          true
        ) else
          find_pos n.next
  in
  find_pos (Some t.head)

let delete t key =
  if key = min_key || key = max_key then false
  else (
    Mutex.lock t.mutex;
    let rec find_pos curr =
      match curr with
      | None -> 
          Mutex.unlock t.mutex;
          false
      | Some n ->
          if n.key = key then (
            let prev_node = Option.get n.prev in
            let next_node = Option.get n.next in
            prev_node.next <- Some next_node;
            next_node.prev <- Some prev_node;
            Mutex.unlock t.mutex;
            true
          ) else if n.key > key then (
            Mutex.unlock t.mutex;
            false
          ) else
            find_pos n.next
    in
    find_pos (Some t.head)
  )

let member t key =
  if key = min_key || key = max_key then false
  else (
    Mutex.lock t.mutex;
    let rec find_pos curr =
      match curr with
      | None -> 
          Mutex.unlock t.mutex;
          false
      | Some n ->
          if n.key = key then (
            Mutex.unlock t.mutex;
            true
          ) else if n.key > key then (
            Mutex.unlock t.mutex;
            false
          ) else
            find_pos n.next
    in
    find_pos (Some t.head)
  )
