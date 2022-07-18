// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
// Chainlink imports for random number
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Errors
error RandomNFT__RangeOutOfBounds();
error RandomNFT__MintFeeIsLow();
error RandomNFT__WithdrawFailed();

contract RandomNFT is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    // State variables
    uint256 public s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_NFTTokenURIs;
    uint256 internal i_mintFee;

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

    // Events
    event NFTRequested(uint256 indexed requestId, address requester);
    event NFTMinted(NFTChoices choice, address minter);


    // Constructor
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        string[3] memory _NFTTokenURIs,
        uint256 mintFee
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("NFT Generator", "NFG") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_NFTTokenURIs = _NFTTokenURIs;
        i_mintFee = mintFee;

    }

    // Pure functions

    // Get Mint Fee
    function getMintFee() public view returns(uint256) {
        return i_mintFee;
    }

    // Get Token uri at index
    function getNFTTokenURI(uint256 index) public view returns(string memory){
        return s_NFTTokenURIs[index];
    }

    // Get Token counter
    function getTokenCounter() public view returns(uint256) {
        return s_tokenCounter;
    }


    // Array
    function getNFTRangeArray() public pure returns(uint256[3] memory){
        return [10, 30, MAX_CHANCE_VALUE];
    }

    // Logic

    function requestNFT() public payable returns (uint256 requestId) {
        if(msg.value < i_mintFee) {
            revert RandomNFT__MintFeeIsLow();
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        s_requestIdToSender[requestId] = msg.sender;
        emit NFTRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        address NFTOwner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;

        uint256 range = randomWords[0] % MAX_CHANCE_VALUE;
        s_tokenCounter += s_tokenCounter;

         NFTChoices choice = getNFTFromRange(range);
        _safeMint(NFTOwner, newTokenId);
        _setTokenURI(newTokenId, s_NFTTokenURIs[uint256(choice)]);
        emit NFTMinted(choice, NFTOwner);

    }

    function getNFTFromRange(uint256 _range) public pure returns (NFTChoices){
       uint256 cumulativeSum = 0;
       uint256[3] memory arrayRange = getNFTRangeArray();
       for(uint256 index= 0; index < arrayRange.length; index++){
        if(_range >= cumulativeSum && _range < cumulativeSum + arrayRange[index]) {
            return NFTChoices(index);
        }
        cumulativeSum += arrayRange[index];
       }

       revert RandomNFT__RangeOutOfBounds();

    }



    // Withdraw the contract balance (Only owner)
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) {
           revert RandomNFT__WithdrawFailed();
        }
    }


}
