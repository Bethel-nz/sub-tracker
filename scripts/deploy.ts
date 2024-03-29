import { ethers, network } from 'hardhat';
import { SubTracker, SubTracker__factory } from '../typechain-types';
import verify from '../utils/verify';

async function main() {
  let INITIAL_PRICE = 1; // 1 wei, apparently my test eth wasnt enough to go past 1 wei
  let SUBSCRIPTION_DURATION = 2419200; // assuming a subscription lasts for 28 days, we multiply 24hours in seconds * 28days
  console.log('Deploying Contract ......');
  const SubTrackerFactory: SubTracker__factory =
    await ethers.getContractFactory('SubTracker');
  const subTracker: SubTracker = await SubTrackerFactory.deploy(
    INITIAL_PRICE,
    SUBSCRIPTION_DURATION
  );
  await subTracker.waitForDeployment();
  console.log(`Deployed Contract to: ${await subTracker.getAddress()}`);
  /* contract address will be displayed if incase you need to transfer eth to the contract */

  if (
    network.config.chainId === process.env.CHAIN_ID &&
    process.env.ETHERSCAN_API_KEY
  ) {
    console.log('Waiting for block confirmations....');
    await subTracker.deploymentTransaction()?.wait(6); // using 6 ticks to check if contract has been confirmed on the blockchain;
    await verify(subTracker.target, []); // verifying the contract;
  }

  /* Using functions*/
  const addressToSubscribe = await subTracker.getAddress();
  await subTracker.setSubscriptionPrice(1);

  try {
    const txResponse = await subTracker.subscribe({
      value: ethers.parseEther('1'),
    }); // Assuming a 1 ETH price
    await txResponse.wait();
    console.log(`Subscription successful for address ${addressToSubscribe}`);
  } catch (error: any) {
    if (error.code === 'INSUFFICIENT_FUNDS') {
      console.error('Insufficient funds for subscription.');
    } else {
      console.error('Subscription failed:', error);
    }
  }

  const addressToCheck = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'; // assuming someone subscribed and you want to check if they have a subscription place the address there
  const isActive = await subTracker.isActiveSubscriber(addressToCheck);
  console.log(`User ${addressToCheck} is active subscriber: ${isActive}`);

  // const expiryTimestamp = await subTracker.getSubscriptionExpiry(
  //   addressToCheck
  // );
  // console.log(`Subscription expiry for ${addressToCheck}:`, expiryTimestamp);

  const totalActiveSubscribers = await subTracker.getTotalActiveSubscribers();
  console.log(`Total active subscribers:`, totalActiveSubscribers.toString());

  const totalInactive = await subTracker.getTotalInactiveSubscribers();
  console.log('Total inactive subscribers:', totalInactive.toString());

  try {
    const txResponse = await subTracker.expireSubscriptions();
    await txResponse.wait();
    console.log('Expired subscriptions');
  } catch (error: any) {
    console.error('Expiration failed:', error);
  }
  try {
    const txResponse = await subTracker.withDraw();
    await txResponse.wait();
    console.log('Withdrawal successful');
  } catch (error: any) {
    console.error('Withdrawal failed:', error);
  }
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error: Error) => {
    console.error('[Deploy Contract]: ', error.message);
    process.exit(1);
  });
