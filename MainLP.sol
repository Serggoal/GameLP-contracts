// SPDX-License-Identifier: MIT

import "./IERC20.sol";

pragma solidity ^0.8.0;

contract MainLP is IERC20 {
    address public owner;
    uint public totalTokens;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    address[] public partner;
    mapping(address => uint) public partnersRate;
    string public name = "GameToken";
    string public symbol = "GAMT";
    uint public contractBalance; 
    uint public rateBankFee = 3;
    uint public sumPartnerToken;
    uint public degree = 1000000000000000000; // 10**18


        constructor() {
        owner = msg.sender;
    }

        modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "Not enough tokens!");
        _;
    }

        modifier onlyOwner() {
        require(msg.sender == owner, "Only an owner");
        _;
    }

    event GetBankFee(address receiver, uint payoutBankFee);
    event RewardPlayer(address _player, uint _reward);
    event Rewarding(address receiver, uint rewardForPlayer);
    event GetPartnerFee(address receiver, uint payoutPartnerFee);

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

// set Partner rate for liquidity providing
    function setPartnerRate(address _partner, uint _rate) public onlyOwner whiteList(_partner) {
       partnersRate[_partner] = _rate;
    }
    function getPartnerRate(address _partner) public view returns(uint) {
       return partnersRate[_partner];
    }

// set main Bank fee
    function setRateBankFee(uint _rateBankFee) public onlyOwner {
      rateBankFee = _rateBankFee;
    }
    function getRateBankFee() public view returns(uint) {
      return rateBankFee;
    }
///////////
    function getBalance() public {
       contractBalance = address(this).balance;
   }

    function decimals() public override pure returns(uint) {
        return 18; 
    }

    function totalSupply() public override view returns(uint) {
        return totalTokens;
    }

    function balanceOf(address account) public override view returns(uint) {
        return balances[account];
    }

    function transfer(address to, uint amount) external override enoughTokens(msg.sender, amount) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function allowance(address holder, address spender) external override view returns(uint) {
        return allowances[holder][spender];
    }

    function approve(address spender, uint amount) external override {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external override enoughTokens(sender, amount) {
        allowances[sender][recipient] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

      // mint tokens for users   
    function mint(address _player, uint amount) public {

        balances[_player] += amount;
        totalTokens += amount;
        getBalance();
      
        emit Transfer(address(0), _player, amount);
    }

          // mint tokens for Bank
    function mintBankToken(uint amount) private {

        balances[owner] += amount;
        totalTokens += amount;
        getBalance();
      
        emit Transfer(address(0), owner, amount);
    }
    /// mint tokens for Partners
    function mintPartnerToken(uint amount) private {

        balances[msg.sender] += amount;
        totalTokens += amount;
        sumPartnerToken += amount;
        getBalance();
      
        emit Transfer(address(0), msg.sender, amount);
    }

    // manually withdrawal 
    
    function rewardTokenHolders(address _tokenHolder, uint _withdrawTokens) public {
        require((_withdrawTokens / 10000) * 10000 >= 1, "too small");
        uint balanceUserTokens = balances[_tokenHolder];
        require(balanceUserTokens != 0, "You haven't tokens!");
        require(_withdrawTokens <= balanceUserTokens, "You have less tokens!");
        
        uint ratePartnerFee = partnersRate[msg.sender];
        uint userTokenBankFee = _withdrawTokens / 100 * rateBankFee;
        uint userTokenPartnerFee = _withdrawTokens / 100 * ratePartnerFee;
        uint payoutUserTokens = _withdrawTokens - userTokenBankFee - userTokenPartnerFee;

        uint payoutUser = payoutUserTokens * contractBalance / totalTokens;
        balances[_tokenHolder] -= _withdrawTokens;
        totalTokens -= _withdrawTokens;

        address payable receiver = payable(_tokenHolder);
        receiver.transfer(payoutUser);
        getBalance();  // может быть лишним

        mintBankToken(userTokenBankFee);
        mintPartnerToken(userTokenPartnerFee);

        emit Rewarding(receiver, payoutUser);
    }
    ////////

    // get Token price
    function _getTokenPrice() public view returns(uint256) {
        return contractBalance * degree / totalTokens; 
    }

    // the process of delivering liquidity to the game. In return for liquidity, it receives tokens

    function depo(address _player, uint _tokensForDepo) public payable whiteList(msg.sender) {
    
          mint(_player, _tokensForDepo);
    }

    //////
    function getBankFee(uint _payoutTokenBankFee) public onlyOwner {
        require((_payoutTokenBankFee / 10000) * 10000 >= 1, "too small");
        uint currentAmountBankTokens = balances[owner];
        require(currentAmountBankTokens != 0, "BankFee is empty!");
        require(_payoutTokenBankFee <= currentAmountBankTokens, "BankFee is lower!");

        uint payoutBankFee = _payoutTokenBankFee * contractBalance / totalTokens;

        balances[owner] -= _payoutTokenBankFee;
        totalTokens -= _payoutTokenBankFee;
        
        address payable receiver = payable(msg.sender);
        receiver.transfer(payoutBankFee);
        getBalance();

        emit GetBankFee(receiver, payoutBankFee);
    }

///////// 
    function getPartnerFee(uint _payoutPartnerTokenFee, address _ownerPartner) public whiteList(msg.sender) {
        require((_payoutPartnerTokenFee / 10000) * 10000 >= 1, "too small");
        uint currentAmountPartnerTokens = balances[msg.sender];
        require(currentAmountPartnerTokens != 0, "PartnerTokenFee is empty!");
        require(_payoutPartnerTokenFee <= currentAmountPartnerTokens, "PartnerTokenFee is lower!");

        uint payoutPartnerFee = _payoutPartnerTokenFee * contractBalance / totalTokens;

        balances[msg.sender] -= _payoutPartnerTokenFee;
        sumPartnerToken -= _payoutPartnerTokenFee;
        totalTokens -= _payoutPartnerTokenFee;
        
        address payable receiver = payable(_ownerPartner);
        receiver.transfer(payoutPartnerFee);
        getBalance();

        emit GetPartnerFee(receiver, payoutPartnerFee);
    }
/////////// for Draw in game
    function payReward(address _player, uint _reward) external {
        payable(_player).transfer(_reward);
        emit RewardPlayer(_player, _reward);
    }

    fallback() external payable {
    }

    receive() external payable {
    }

}