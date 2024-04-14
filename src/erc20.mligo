module ERC20 = struct
  type storage =
    {
     totalSupply : nat;
     balances : (address, nat) big_map;
     name : string;
     symbol : string;
     owner : address
    }

  type result = operation list * storage

  module Errors = struct
    let not_admin = "Not admin"

    let not_found = "Balance not found"

    let no_money = "Not enough money in bank"

    let no_more_supply = "Not enough money in supply"
    end

  let updateValue
    (balances : (address, nat) big_map)
    (caller : address)
    (amount : nat)
  : (address, nat) big_map =
    let new_balance =
      match Big_map.find_opt caller balances with
        None -> amount
      | Some old_balance -> old_balance + amount in
    Big_map.update caller (Some new_balance) balances

  [@entry]
  let mint (caller, amount : address * nat) (storage : storage) : result =
    let _ =
      assert_with_error (Tezos.get_sender () = storage.owner) Errors.not_admin in
    let new_total_supply = storage.totalSupply + amount in
    let new_balances = updateValue storage.balances caller amount in
    let new_storage =
      {storage with totalSupply = new_total_supply; balances = new_balances} in
    ([], new_storage)

  [@entry]
  let transfer (from, to_, amount : address * address * nat) (storage : storage)
  : result =
    let from_balance =
      match Big_map.find_opt from storage.balances with
        None -> failwith Errors.not_found
      | Some balance -> balance in
    let to_balance =
      match Big_map.find_opt to_ storage.balances with
        None -> abs (0)
      | Some balance -> balance in
    let _ = assert_with_error (from_balance <= amount) Errors.no_money in
    let new_from_balance = abs (from_balance - amount) in
    let new_to_balance = to_balance + amount in
    let new_balances =
      Big_map.update from (Some new_from_balance) storage.balances
      |> Big_map.update to_ (Some new_to_balance) in
    let new_storage = {storage with balances = new_balances} in
    ([], new_storage)

  [@entry]
  let burn (caller, amount : address * nat) (storage : storage) : result =
    let _ =
      assert_with_error (Tezos.get_sender () = storage.owner) Errors.not_admin in
    let new_total_supply = abs (storage.totalSupply - amount) in
    let from_balance =
      match Big_map.find_opt caller storage.balances with
        None -> failwith Errors.not_found
      | Some balance -> balance in
    let _ = assert_with_error (from_balance <= amount) Errors.no_money in
    let new_balances =
      updateValue storage.balances caller (abs (from_balance - amount)) in
    let new_storage =
      {storage with totalSupply = new_total_supply; balances = new_balances} in
    ([], new_storage)
  end
