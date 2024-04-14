#import "../.ligo/source/i/ligo_extendable_fa2__1.0.4__ffffffff/lib/main.mligo" "FA2"

module TOKEN = struct
  type extension = {owner : address}

  type storage = extension FA2.SingleAsset.storage

  type result = operation list * storage

  [@entry]
  let mint (amount : nat) (storage : storage) : result =
    let sender = Tezos.get_sender () in
    let _ = assert (sender = storage.extension.owner) in
    let _ =
      assert_with_error
        (sender = storage.extension.owner)
        "mint: you are not the owner" in
    let updated_storage =
      FA2.SingleAsset.Ledger.increase_token_amount_for_user
        storage.ledger
        sender
        amount in
    let new_storage = {storage with ledger = updated_storage} in
    ([], new_storage)

  [@entry]
  let transfer (transfer : FA2.SingleAsset.transfer) (storage : storage)
  : result = FA2.SingleAsset.transfer transfer storage

  [@entry]
  let balance_of (balance : FA2.SingleAsset.balance_of) (storage : storage)
  : result = FA2.SingleAsset.balance_of balance storage

  [@entry]
  let update_ops
    (updates : FA2.SingleAsset.update_operators)
    (storage : storage)
  : result = FA2.SingleAsset.update_ops updates storage
  end
