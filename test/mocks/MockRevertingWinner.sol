// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @dev This contract reverts when funds are sent to it. Used for testing that
 * @dev `fulfillRandomWords` reverts if prize transfer to the winner fails.
 */
contract MockRevertingWinner {
    error MockRevertingWinner_FundsReceived();

    receive() external payable {
        revert MockRevertingWinner_FundsReceived();
    }
}
