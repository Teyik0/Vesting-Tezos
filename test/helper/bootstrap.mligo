let boot_accounts ()
: (address * address * address * address * address * address * address) =
  let () =
    Test.reset_state
      8n
      ([
         10000000000000mutez;
         4000000000000mutez;
         4000000000000mutez;
         4000000000000mutez;
         4000000000000mutez
       ]
       : tez list) in
  let owner1 = Test.nth_bootstrap_account 1 in
  let owner2 = Test.nth_bootstrap_account 2 in
  let owner3 = Test.nth_bootstrap_account 3 in
  let owner4 = Test.nth_bootstrap_account 4 in
  let owner5 = Test.nth_bootstrap_account 5 in
  let owner6 = Test.nth_bootstrap_account 6 in
  let owner7 = Test.nth_bootstrap_account 7 in
  let resultat = (owner1, owner2, owner3, owner4, owner5, owner6, owner7) in
  resultat
