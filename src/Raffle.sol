// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title A sample Raffle contract
 * @author Ismail Dawoodjee
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5 (Verifiable Random Function)
 */
contract Raffle {
    /* STATE VARIABLES */
    uint256 private immutable i_raffleEntranceFee; // Entrance fee for entering the raffle
    address payable[] private s_listOfPlayers;
    uint256 private immutable i_lotteryDurationSeconds; // How long each round of lottery lasts before picking a winner
    uint256 private s_lastRecordedTimeStamp; // The last timestamp that was recorded

    /* EVENTS */
    event NewPlayerHasEnteredRaffle(address indexed _newPlayer);

    /* ERRORS */
    error Raffle__NotEnoughEthToEnterRaffle();

    /* CONSTRUCTOR */
    constructor(uint256 _raffleEntranceFee, uint256 _lotteryDurationSeconds) {
        i_raffleEntranceFee = _raffleEntranceFee;
        i_lotteryDurationSeconds = _lotteryDurationSeconds;
        s_lastRecordedTimeStamp = block.timestamp; // Initialized to when the contract is first deployed (first block)
    }

    function enterRaffle() external payable {
        if (msg.value < i_raffleEntranceFee) revert Raffle__NotEnoughEthToEnterRaffle();

        s_listOfPlayers.push(payable(msg.sender)); // Player is going to be the address that called this function
        emit NewPlayerHasEnteredRaffle(msg.sender);
    }

    /**
     * 1. This function needs to get a random number from VRF
     * 2. Then it needs to use the random number to pick out a winner
     * 3. Finally, it needs to be called automatically, at periodic intervals
     *
     * Getting a random number is a two-transaction process:
     * 1. First, we send a transaction to request a random number from the subscription
     * 2. In the next transaction, we get that random number from the oracle
     */
    function pickRaffleWinner() external {
        // We want to check to see if enough time has passed before picking the winner
        if (block.timestamp - s_lastRecordedTimeStamp > i_lotteryDurationSeconds) {
            revert();
        }
    }

    /* GETTER FUNCTIONS */
    function getRaffleEntranceFee() external view returns (uint256) {
        return i_raffleEntranceFee;
    }

    function getPlayerAddress(uint256 _playerIndex) external view returns (address) {
        return s_listOfPlayers[_playerIndex];
    }

    function getLotteryDuration() external view returns (uint256) {
        return i_lotteryDurationSeconds;
    }
}
