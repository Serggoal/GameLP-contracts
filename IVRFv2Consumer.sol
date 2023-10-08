// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRFv2Consumer {
    function requestRandomWords() external returns (uint256 requestId);

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external;

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords);

    function getCurrentRandom(uint _requestId) external view returns(uint256);

    function getFulfillStatus(uint _requestId) external view returns(bool);

    function existOrNot(uint _requestId) external view returns(bool);

    function getLastRequestId() external view returns(uint);

    function closeRandom(uint _requestId) external;

}