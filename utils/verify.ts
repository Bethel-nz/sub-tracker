import { run } from 'hardhat';
import { Addressable } from 'ethers';

//Verifies the contract with its abi using etherscan
const verify = async (contractAddress: string | Addressable, args: any[]) => {
  console.log('Verifying contract...');
  try {
    await run('verify:verify', {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (error: any) {
    if (error.message.toLowerCase().includes('already verified')) {
      console.log('Already verified!');
    } else {
      console.log(error);
    }
  }
};

export default verify;
