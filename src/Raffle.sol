// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title A sample Raffle contract
 * @author Ismail Dawoodjee
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5 (Verifiable Random Function)
 */
contract Raffle {
    // entrance fee for entering the raffle
    uint256 private immutable i_entranceFee;

    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}

    /*//////////////////////////////////////////////////////////////
                           GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
