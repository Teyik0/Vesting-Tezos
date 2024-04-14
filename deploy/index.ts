import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit } from '@taquito/taquito';

import vestingContract from '../compiled/vesting.mligo.json';
import tokenContract from '../compiled/fa2_single_asset.mligo.json';

const RPC_ENDPOINT = 'https://ghostnet.tezos.marigold.dev';

async function main() {
  const Tezos = new TezosToolkit(RPC_ENDPOINT);

  //set alice key
  Tezos.setProvider({
    signer: await InMemorySigner.fromSecretKey(
      'edskS6o6PW4oJxCpXB4et2jpzvJYcQZpmH5qavVWrv59atDMjFmug4EurAbHe6Xr5R9yeVLWPeFyyDw5dZNiEUyRHGN5sfCE73'
    ),
  });

  const initialStorage = {
    metadata: {},
    owner: 'tz1bJt2NAQFJ47J322zJjKudLA91oT4vtY3u',
    value: '0',
  };

  try {
    const originated = await Tezos.contract.originate({
      code: tokenContract,
      storage: initialStorage,
    });
    console.log(
      `Waiting for myContract ${originated.contractAddress} to be confirmed...`
    );
    await originated.confirmation(2);
    console.log('confirmed contract: ', originated.contractAddress);
  } catch (error: any) {
    console.log(error);
  }
}

main();
