pragma solidity 0.5.11;

contract Betting {

    /*
    * Storage
    */

    address payable public owner;
    uint public lastWinnerNumber;
    uint public betValue = 1 ether;
    uint public totalBet;
    uint public numberOfBets;
    uint public totalSlots = 4;
    address[] public players;

    mapping(uint => address payable[]) public numberToPlayers;
    mapping(address => uint) public playerToNumber;

    /*
    * Modifiers
    */

    modifier validBet(uint betNumber) {
        require(playerToNumber[msg.sender] == 0, "Only can bet once");
        require(msg.value >= betValue, "Not enough balance!");
        require(numberOfBets < 10, "Only 9 players");
        require(betNumber >= 1 && betNumber <= 10, "Only in range 1 and 10");
        _;
    }

    constructor(address payable _owner) public {
        owner = _owner;
    }

    function bet(uint betNumber)
        public
        payable
        validBet(betNumber) {
        require(msg.sender.balance >= msg.value, "Not enough balance to excute transaction!");
        if (msg.value > betValue) {
            msg.sender.transfer(msg.value - betValue);
        }
        playerToNumber[msg.sender] = betNumber;
        players.push(msg.sender);
        numberToPlayers[betNumber].push(msg.sender);
        numberOfBets += 1;
        totalBet += msg.value;
        if(numberOfBets >= totalSlots) {
            distributePrizes();
        }
    }

    function distributePrizes() internal {
        uint winnerNumber = generateRandomNumber();
        address payable[] memory winners = numberToPlayers[winnerNumber];
        if (winners.length > 0) {
            uint winnerEtherAmount = ((totalBet/100) * 80) / winners.length;
            owner.transfer((totalBet/100)*20);
            for (uint i = 0; i < numberToPlayers[winnerNumber].length; i++) {
                numberToPlayers[winnerNumber][i].transfer(winnerEtherAmount);
            }
        } else {
            owner.transfer(totalBet);
        }
        lastWinnerNumber = winnerNumber;
        reset();
    }

    function generateRandomNumber() internal view returns (uint) {
        return ((block.number + block.timestamp + block.difficulty) % 10 + 1);
    }

    function reset() internal {
        for (uint i = 1; i <= 10; i++) {
            numberToPlayers[i].length = 0;
        }

        for (uint j = 0; j < players.length; j++) {
            playerToNumber[players[j]] = 0;
        }

        players.length = 0;
        totalBet = 0;
        numberOfBets = 0;
    }

    function kill() public {
        require(msg.sender == owner, "Only owner call call this!");
        selfdestruct(owner);
    }
}
