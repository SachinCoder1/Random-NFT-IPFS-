const { network, ethers } = require("hardhat");
const {
  developmentChains,
  networkConfig,
} = require("../helper-hardhat-config");
const { storeImages, storeMetaData } = require("../utils/uploadToPinata");
const { verify } = require("../utils/verify");
const imageFileLocation = "./images";

const nftMetaData = {
  name: "",
  description: "",
  image: "",
  attributes: [
    {
      trait_type: "monkey",
      value: 100,
    },
  ],
};


const FUND_AMOUNT = "10000000000000000000000"

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;

  //  handleTokenURIs;

  let handleTokenURIs = async () => {
    let tokenURIs = [];
    const { responses, files } = await storeImages(imageFileLocation);
    for (responseIndex in responses) {
      let tokenMetaData = { ...nftMetaData };
      tokenMetaData.name = files[responseIndex].replace(".png", ""); // for name of tokenUri;
      tokenMetaData.description = `This ${tokenMetaData.name} nft is made with love! `;
      tokenMetaData.image = `ipfs://${responses[responseIndex].IpfsHash}`;
      console.log(
        "uploading meta data image of ",
        tokenMetaData.name,
        "-------------------"
      );
      const metaDataResponse = await storeMetaData(tokenMetaData);

      tokenURIs.push(`ipfs://${metaDataResponse.IpfsHash}`);
    }

    console.log("Token Uris meta data uploadind --------------------------");
    console.log(tokenURIs);

    return tokenURIs;
  };

  let tokenURIs = [
    'ipfs://QmUVPL885Di7RDbnWkFm2sLjgSua4imDDiJZQrpKk4z2Bj',
    'ipfs://Qmf7jQMfDQr9Hsa6T7sjAEXFaaTg5FiE5VoQceFeRBKndX',
    'ipfs://QmYY7cKG1exY3BrbRGJyUYXfSPSaucyxX1JpMQAgTvB51G'
  ];
  if ((process.env.UPLOAD_TO_PINATA == true)) {
    tokenURIs = await handleTokenURIs();
  }

  let vrfCoordinatorV2Address, subscriptionId;

  if (developmentChains.includes(network.name)) {
    const vrfCoordinatorV2Mock = await ethers.getContract(
      "VRFCoordinatorV2Mock"
    );
    vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address;

    const transactionResponse = await vrfCoordinatorV2Mock.createSubscription();
    const transactionReceipt = await transactionResponse.wait(1);

    subscriptionId = transactionReceipt.events[0].args.subId;

    await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, FUND_AMOUNT)
  } else {
    vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
    subscriptionId = networkConfig[chainId]["subscriptionId"];
  }

  const mintFee = networkConfig[chainId]["mintFee"];
  const gasLane = networkConfig[chainId]["gasLane"];
  const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"];

  await storeImages(imageFileLocation);

  const args = [
    vrfCoordinatorV2Address,
    subscriptionId,
    gasLane,
    callbackGasLimit,
    tokenURIs,
    mintFee,
  ];
  log("Started Deploying random NFT -------------------------------------------------")

  const randomIPFSNFT = await deploy("RandomNFT", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1
  })

  log("Depoyed random NFT -------------------------------------------------")

  if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY){
    log("Verifying---------------------");
    await verify(randomIPFSNFT.address, args);
  }
};

module.exports.tags = ["all", "randomipfs", "deploynft"];
