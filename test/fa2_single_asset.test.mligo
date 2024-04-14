(* This is mycontract-test.mligo *)

#import "./helper/bootstrap.mligo" "Bootstrap"
#import "./helper/assert.mligo" "Assert"
#import "../src/fa2_single_asset.mligo" "MyContract"
#import "../.ligo/source/i/ligo_extendable_fa2__1.0.4__ffffffff/lib/main.mligo" "FA2"

type storage = MyContract.TOKEN.storage

type parameter =
| Balance_of of FA2.MultiAsset.balance_of
| Mint of nat
| Transfer of FA2.MultiAsset.transfer
| Update_ops of FA2.MultiAsset.update_operators

let nth_exn (type a) (i : int) (a : a list) : a =
  let rec aux (remaining : a list) (cur : int) : a =
    match remaining with
      [] -> failwith "Not found in list"
    | hd :: tl -> if cur = i then hd else aux tl (cur + 1) in
  aux a 0

let get_initial_storage (a, b, c : nat * nat * nat) =
  let () = Test.reset_state 6n ([] : tez list) in
  let owner1 = Test.nth_bootstrap_account 0 in
  let owner2 = Test.nth_bootstrap_account 1 in
  let owner3 = Test.nth_bootstrap_account 2 in
  let owners = [owner1; owner2; owner3] in
  let op1 = Test.nth_bootstrap_account 3 in
  let op2 = Test.nth_bootstrap_account 4 in
  let op3 = Test.nth_bootstrap_account 5 in
  let ops = [op1; op2; op3] in
  let ledger = Big_map.literal ([(owner1, a); (owner2, b); (owner3, c)]) in
  let operators =
    Big_map.literal
      ([
         (owner1, Set.literal [op1]);
         (owner2, Set.literal [op1; op2]);
         (owner3, Set.literal [op1; op3]);
         (op3, Set.literal [op1; op2])
       ]) in
  let token_info = (Map.empty : (string, bytes) map) in
  let token_metadata =
    Big_map.literal
      ([
         (0n,
          {
           token_id = 0n;
           token_info = token_info
          })
       ]) in
  let initial_storage =
    {
     metadata =
       Big_map.literal
         [
           ("", Bytes.pack ("tezos-storage:contents"));
           ("contents", ("" : bytes))
         ];
     ledger = ledger;
     token_metadata = token_metadata;
     operators = operators;
     extension = {owner = owner1}
    } in
  initial_storage, owners, ops

let assert_balances
  (contract_address : (parameter, storage) typed_address)
  (a, b, c : (address * nat) * (address * nat) * (address * nat)) =
  let (owner1, balance1) = a in
  let (owner2, balance2) = b in
  let (owner3, balance3) = c in
  let storage = Test.get_storage contract_address in
  let ledger = storage.ledger in
  let () =
    match (Big_map.find_opt owner1 ledger) with
      Some amt -> assert (amt = balance1)
    | None -> failwith "incorret address" in
  let () =
    match (Big_map.find_opt owner2 ledger) with
      Some amt -> assert (amt = balance2)
    | None -> failwith "incorret address" in
  let () =
    match (Big_map.find_opt owner3 ledger) with
      Some amt -> assert (amt = balance3)
    | None -> failwith "incorret address" in
  ()

let test_atomic_tansfer_success =
  let initial_storage, owners, operators = get_initial_storage (10n, 10n, 10n) in
  let owner1 = nth_exn 0 owners in
  let owner2 = nth_exn 1 owners in
  let owner3 = nth_exn 2 owners in
  let op1 = nth_exn 0 operators in
  let transfer_requests =
    ([
       ({
         from_ = owner1;
         txs =
           ([
              {
               to_ = owner2;
               token_id = 0n;
               amount = 2n
              };
              {
               to_ = owner3;
               token_id = 0n;
               amount = 3n
              }
            ]
            : FA2.SingleAsset.atomic_trans list)
        })
     ]
     : FA2.SingleAsset.transfer) in
  let () = Test.set_source op1 in
  let {
   addr;
   code = _;
   size = _
  } = Test.originate (contract_of  MyContract.TOKEN) initial_storage 0mutez in
  let contr = Test.to_contract addr in
  let () = Test.set_source owner1 in
  let _ = Test.transfer_to_contract contr (Transfer transfer_requests) 0mutez in
  // let () = assert_balances addr ((owner1, 8n), (owner2, 7n), (owner3, 15n)) in
  let storage = Test.get_storage addr in
  let ledger = storage.ledger in
  let test =
    match (Big_map.find_opt owner1 ledger) with
      Some amt -> assert (amt = 5n)
    | None -> failwith "incorrect address" in
  ()
