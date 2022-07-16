// SPDX-License-Identifier: MIT

// Chainlink imports for random number
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

pragma solidity ^0.8.7;

contract RandomNFT is VRFConsumerBaseV2, ERC721 {
    // State variables
    uint256 public s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;

    // Enums
    enum NFTChoices {
      PUG, SHIBA, ST_BERNARD
    }

    // Chainlink variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Mappings
    mapping (uint256=>address) s_requestIdToSender;


    // Constructor
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("NFT Generator", "NFG") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    // Pure functions
    function tokenURI(uint256) public view override returns(string memory){
        // return token_URI
    }

    // Array
    function getNFTRangeArray() public pure returns(uint256[3] memory){
        return [10, 30, MAX_CHANCE_VALUE];
    }

    // Logic

    function requestNFT() public returns (uint256 requestId) {
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        s_requestIdToSender[requestId] = msg.sender;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        address dogOwner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;
        _safeMint(dogOwner, newTokenId);

        uint256 range = randomWords[0] % MAX_CHANCE_VALUE;

    }

    function getNFTFromRange(uint256 _range) public pure returns (NFTChoices){
       uint256 cumulativeSum = 0;
       uint256[3] memory arrayRange = getNFTRangeArray();
       
    }


}
