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
    // entrance fee for entering the raffle
    uint256 private immutable i_entranceFee;

    /* ERRORS */
    error Raffle__SendMoreToEnterRaffle();

    /* CONSTRUCTOR */
    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
    }

    function enterRaffle() public payable {
        if (msg.value <= i_entranceFee) revert Raffle__SendMoreToEnterRaffle();
    }

    function pickWinner() public {}

    /* GETTER FUNCTIONS */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
