module CALLER = struct
  type storage = address

  type result = operation list * storage

  type counter_parameter =
  | Increment of int
  | Decrement of int
  | Reset of unit

  let get_contract (store : storage) : counter_parameter contract =
    let maybe_contract = Tezos.get_contract_opt store in
    match maybe_contract with
      None -> failwith "Contract does not exist"
    | Some contract -> contract

  [@entry]
  let call_increment (delta : int) (store : storage) : result =
    let counter_contract = get_contract (store) in
    let op = Tezos.transaction (Increment delta) 0mutez counter_contract in
    ([op], store)

  [@entry]
  let call_decrement (delta : int) (store : storage) : result =
    let counter_contract = get_contract (store) in
    let op = Tezos.transaction (Decrement delta) 0mutez counter_contract in
    ([op], store)

  [@entry]
  let call_reset () (store : storage) : result =
    let counter_contract = get_contract (store) in
    let op = Tezos.transaction Reset 0mutez counter_contract in
    ([op], store)
  end
