// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface InterfaceMainLP {
    // function setPartner(address _partner) external;

    // function checkWhiteList(address _partner) external view returns(bool);

    // function setPartnerRate(address _partner, uint _rate) external;

    // function getPartnerRate(address _partner) external view returns(uint);

    // function setRateBankFee(uint _rateBankFee) external;

    // function getRateBankFee() external view returns(uint);

    function getBalance() external;

    // function decimals() external pure returns(uint);

    // function totalSupply() external view returns(uint);

    // function balanceOf(address account) external view returns(uint);

    // function transfer(address to, uint amount) external;

    // function allowance(address holder, address spender) external view returns(uint);

    // function approve(address spender, uint amount) external;

    // function transferFrom(address sender, address recipient, uint amount) external;

    function mint(address _player, uint amount) external;

    // function mintBankToken(uint amount) external;

    // function mintPartnerToken(uint amount) external;

    function rewardTokenHolders(address _tokenHolder, uint _withdrawTokens) external;

    // function _howManyRewards(address _player) external returns(uint);

    function depo(address _player, uint _tokensForDepo) external payable;

    // function getBankFee(uint _bankFee) external;

    function getPartnerFee(uint _partnerFee, address owner) external;

    function payReward(address _player, uint _reward) external;

}
