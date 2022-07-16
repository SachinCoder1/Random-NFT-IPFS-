const {network, ethers} = require('hardhat');
const {developmentChains} = require('../helper-hardhat-config');
const {verify} = require('../utils/verify');

module.exports = async ({getNamedAccounts, deployments}) => {
  const {deploy, log} = deployments;
  const {deployer} = await getNamedAccounts();
  const chainId = network.config.chainId;

   
//  handleTokenURIs;
   
let handleTokenURIs = async () => {
    let tokenURIs = [];


    return tokenURIs;
}

  let tokenURIs;
  if(process.env.IS_PINATA = true){
    tokenURIs = await handleTokenURIs();
  }




  let vrfCoordinatorV2Address, subscriptionId;

  if(developmentChains.includes(network.name)){
    const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock");
    vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address;

    const transactionResponse = await vrfCoordinatorV2Mock.createSubscription();
    const transactionReceipt = await transactionResponse.wait(1);

    subscriptionId = transactionReceipt.events[0].args.subId

  }else {
    vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
    subscriptionId = networkConfig[chainId]["subscriptionId"];
  }




  const mintFee = networkConfig[chainId]["mintFee"];
  const gasLane = networkConfig[chainId]["gasLane"];
  const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"];


  const args = [vrfCoordinatorV2Address, subscriptionId, gasLane, callbackGasLimit,mintFee ]
  

}