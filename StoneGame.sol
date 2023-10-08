// SPDX-License-Identifier: MIT

import "./InterfaceMainLP.sol";
import "./IVRFv2Consumer.sol";

pragma solidity ^0.8.0;

contract StoneGame {
        address public owner;
        uint public userBet;
        uint public userChoice;
        address public addressPlayer;
        uint public degree = 1000000000000000000; // 10**18
        uint public rateGame = 500000000000000; // 0,0005 
        uint public rateDepo = 100000000000000; // 0,0001 
        uint public minDepo = 10000000000000000; // 0,01 Eth 
        uint public minBet = 1000000000000000; // 0,001 Eth

        uint public botChoice;
        uint public rate = 9;
        bool public nextUser;
        uint public currentRandomWord;
        uint public randomNumber;
        uint public roundWinner;

        IVRFv2Consumer random_contract;
        InterfaceMainLP main_contract;
        address public main_payable;

    constructor(address _random_contract, address _main_contract) {
        owner = msg.sender;
        random_contract = IVRFv2Consumer(_random_contract);
        main_contract = InterfaceMainLP(_main_contract);
        main_payable = _main_contract;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only an owner");
        _;
    }

    event Rewarding(address receiver, uint howManyRewards);
    event Draw(string);

  // start game: tx contains 1) userChoice and 2) bet
    function startRequestRandom(uint256 _userChoice) public payable {
        require(!nextUser, "Wait in line");
        require(msg.sender != owner, "You are Owner!");
        require(msg.value >= minBet, "Need more 0.001");
        uint mainBalance = address(main_contract).balance;

        require(msg.value < mainBalance / 2, "Not enouth funds in game!");
        random_contract.requestRandomWords();
        address payable toPay = payable(main_payable);
        toPay.transfer(msg.value);
        userBet = msg.value;
        addressPlayer = payable(msg.sender);
        userChoice = _userChoice;
        nextUser = !nextUser;
    }
 // summing up the results
    function getGameStatus(uint256 _requestId) public {
        require(nextUser, "Wait next play!");
        require(random_contract.existOrNot(_requestId), "request not found");
        require(msg.sender == addressPlayer, "You aren't player. Wait in line!");
        require(random_contract.getFulfillStatus(_requestId), "Wait random!");

        currentRandomWord = random_contract.getCurrentRandom(_requestId);
        randomNumber = currentRandomWord % rate;

           if(randomNumber <= 2) {
            botChoice = randomNumber;
            roundWinner = checkWinner(userChoice, botChoice);
           } else {
            roundWinner = 0;
           }

        playGame(roundWinner);
        nextUser = !nextUser;
        random_contract.closeRandom(_requestId);
    }

    function checkWinner(uint256 _userChoice, uint256 _botChoice) public pure returns(uint){

          if(_userChoice == _botChoice){
              return 2;
            }
          if(_userChoice == 0 && _botChoice == 1 || _userChoice == 1 && _botChoice == 2 || _userChoice == 2 && _botChoice == 0 ){
            return 1;
            }
          return 0;
          }

    function playGame(uint _result) internal {

        uint rewardPlayer = userBet * 2;
        uint tokensToGame;

        if(_result == 1) {
            main_contract.payReward(addressPlayer, rewardPlayer);
            main_contract.getBalance();
            emit Rewarding(addressPlayer, rewardPlayer);
        } else if(_result == 0) {
            tokensToGame = userBet * degree / rateGame;
            main_contract.mint(addressPlayer, tokensToGame);
            emit Rewarding(addressPlayer, tokensToGame);
        } else if(_result == 2) {
            main_contract.payReward(addressPlayer, userBet);
            emit Draw("Draw");
        }
        
    }
/////////// just view - temporary
    function seeRandomNumber() public view returns (uint){
        return getRandomNumber(random_contract.getLastRequestId()) % 100;
    }
    function seeRandomNumber3() public view returns (uint){
        return getRandomNumber(random_contract.getLastRequestId()) % rate;
    }

    function getRandomNumber(uint256 _requestId) internal view returns (uint _randomNumber) {
        require(random_contract.existOrNot(_requestId), "request not found");

        return random_contract.getCurrentRandom(_requestId);
    }
//////////////
    function setRate(uint _rate) public onlyOwner {
       rate = _rate;
    }

    function setRateGame(uint _rateGame) public onlyOwner {
      rateGame = _rateGame;
    }

    function setRateDepo(uint _rateDepo) public onlyOwner {
      rateDepo = _rateDepo;
    }
//////// delivering liquidity to the game
    function depo() public payable {
        require(msg.sender != owner, "You are an Owner!");
        require(msg.value >= minDepo, "Incorrect sum!"); // 0,01 Eth
    
        uint tokensForDepo = msg.value / rateDepo * degree;
        main_contract.depo{value: msg.value}(msg.sender, tokensForDepo);
    }
//////// change tokens to eth
    function rewardTokenUsers(uint _withdrawTokens) public {
        main_contract.rewardTokenHolders(msg.sender, _withdrawTokens);
    }
//////// change Partner tokens to eth
    function getPartnerReward(uint _partnerTokenReward) public onlyOwner {
        main_contract.getPartnerFee(_partnerTokenReward, owner);
    }

}