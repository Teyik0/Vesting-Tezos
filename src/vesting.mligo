#import "./fa2_single_asset.mligo" "TOKEN"

module VESTING = struct
  type storage =
    {
     owner : address;
     beneficiaries : (address, bool) big_map;
     freeze_duration : nat;
     start_vesting_date : timestamp;
     has_started : bool;
     fa2tokenAddress : address;
     fa2tokenId : nat
    }

  type result = operation list * storage

  let one_day : int = 86400

  let claimable_amount = 1000n

  let get_entrypoint (addr, name : address * string) =
    if name = "increment"
    then
      match Tezos.get_entrypoint_opt "%increment" addr with
        Some contract -> contract
      | None -> failwith "Error"
    else failwith "Unsupported entrypoint"

  [@entry]
  let start (freeze_duration : nat) (storage : storage) : result =
    let _ =
      assert_with_error
        (storage.has_started = false)
        "start: the start function has already being used" in
    let _ =
      assert_with_error
        (Tezos.get_sender () = storage.owner)
        "mint: you are not the owner" in
    let new_storage =
      {
        storage with
          freeze_duration = freeze_duration;
          has_started = true;
          start_vesting_date = Tezos.get_now ()
      } in
    ([], new_storage)

  [@entry]
  let addBeneficiary (beneficiary : address) (storage : storage) : result =
    let _ =
      assert_with_error
        (Tezos.get_sender () = storage.owner)
        "addBeneficiary: you are not the owner" in
    let _ =
      assert_with_error
        (storage.has_started)
        "addBeneficiary: the vesting has already started, you can't add a new beneficiary" in
    let _ =
      assert_with_error
        (not (Big_map.mem beneficiary storage.beneficiaries))
        "addBeneficiary: beneficiary already exists" in
    let new_beneficiaries = Big_map.add beneficiary false storage.beneficiaries in
    let new_storage = {storage with beneficiaries = new_beneficiaries} in
    ([], new_storage)

  [@entry]
  let claim (claimerAddress : address) (storage : storage) : result =
    let _ =
      assert_with_error
        (Big_map.mem claimerAddress storage.beneficiaries)
        "Vesting: not a beneficiary" in
    let _ =
      assert_with_error
        (Big_map.find claimerAddress storage.beneficiaries = false)
        "Vesting: token already claim" in
    let _ =
      assert_with_error
        (storage.start_vesting_date + storage.freeze_duration * one_day
         <= Tezos.get_now ())
        "Vesting: tokens are still frozen" in
    let new_beneficiaries =
      Big_map.update claimerAddress (Some true) storage.beneficiaries in
    let new_storage = {storage with beneficiaries = new_beneficiaries} in
    let transfer = get_entrypoint (storage.fa2tokenAddress, "transfer") in
    let transfer_info : TOKEN.FA2.SingleAsset.transfer =
      [
        {
         from_ = Tezos.get_self_address ();
         txs =
           [
             {
              to_ = Tezos.get_sender ();
              token_id = storage.fa2tokenId;
              amount = claimable_amount
             }
           ]
        }
      ] in
    let operation = Tezos.transaction transfer_info 0mutez transfer in
    ([operation], new_storage)
  end
