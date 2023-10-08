// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract VRFv2Consumer is VRFConsumerBaseV2 {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    address[] public partner;
    address public owner;

    /**
     * HARDCODED COORDINATOR FOR SEPOLIA : 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     * For Mumbai COORDINATOR:0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
     */
    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only an owner");
        _;
    }
    function setPartner(address _partner) public onlyOwner {
       partner.push(_partner);
    }
    function checkWhiteList(address _partner) private view returns(bool) {
        bool truePartner;
        uint lenght = partner.length;
        for (uint i = 0; i < lenght; i++) {
            if(partner[i] == _partner) {
              truePartner = true;
            }
        }
        return truePartner;
    }
    modifier whiteList(address _partner) {
        require(checkWhiteList(_partner), "Not a partner!");
        _;
    }

    function deletePartner(address _partner) public onlyOwner {
        uint lenght = partner.length;
        for (uint i = 0; i < lenght; i++) {
            if(partner[i] == _partner) {
              partner[i] = 0x0000000000000000000000000000000000000000;
            }
        }
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external whiteList(msg.sender)
        returns (uint256 requestId)
    {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
////////////////////////////// new
    function getCurrentRandom(uint _requestId) external view returns(uint256) {  
        RequestStatus memory request = s_requests[_requestId];
        return request.randomWords[0];
    }
    function getFulfillStatus(uint _requestId) external view returns(bool) {
        return s_requests[_requestId].fulfilled;
    }

    function existOrNot(uint _requestId) external view returns(bool) {  
        return s_requests[_requestId].exists;
    }
    function getLastRequestId() external view returns(uint) {
        return lastRequestId;
    }
    function closeRandom(uint _requestId) external {
        s_requests[_requestId].exists = false;
    }

}
