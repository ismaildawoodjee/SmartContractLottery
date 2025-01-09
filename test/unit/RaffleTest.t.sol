// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console2 as console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    /* STATE VARIABLES */
    /* CONTRACTS */
    Raffle public s_raffle;
    HelperConfig public s_helperConfig;

    /* MOCK PLAYER */
    address public s_alice = makeAddr("Alice");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    /* CONSTRUCTOR PARAMETERS */
    uint256 s_raffleEntranceFee;
    uint256 s_lotteryDurationSeconds;
    bytes32 s_keyHash;
    uint256 s_subscriptionId;
    uint32 s_callbackGasLimit;
    bool s_enableNativePayment;
    address s_vrfCoordinator;

    /* SETUP AND DEPLOYMENT FUNCTION */
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (s_raffle, s_helperConfig) = deployer.deployRaffleContract();
        HelperConfig.NetworkConfig memory networkConfig = s_helperConfig.getConfig();

        s_raffleEntranceFee = networkConfig.raffleEntranceFee;
        s_lotteryDurationSeconds = networkConfig.lotteryDurationSeconds;
        s_keyHash = networkConfig.keyHash;
        s_subscriptionId = networkConfig.subscriptionId;
        s_callbackGasLimit = networkConfig.callbackGasLimit;
        s_enableNativePayment = networkConfig.enableNativePayment;
        s_vrfCoordinator = networkConfig.vrfCoordinator;

        vm.deal(s_alice, STARTING_PLAYER_BALANCE);
    }

    /* TESTS FOR ENTERING RAFFLE */
    /**
     * assert(s_raffle.getRaffleState() == Raffle.RaffleState.OPEN); //*works
     * assertEq(s_raffle.getRaffleState(), Raffle.RaffleState.OPEN); //?errors
     * Why this errors? Because `assertEq` does not have an overload for an
     * enum type of `RaffleState`. It only has overloads for uint256, bytes, etc.
     */
    function test_RaffleInitializes_InOpenState() public view {
        assertEq(uint256(s_raffle.getRaffleState()), uint256(Raffle.RaffleState.OPEN));
        assert(uint256(s_raffle.getRaffleState()) == 0);
        assert(s_raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function test_RaffleReverts_WhenPaymentNotEnough() public {
        vm.prank(s_alice); // Arrange
        vm.expectRevert(Raffle.Raffle__NotEnoughEthToEnterRaffle.selector); // Act
        s_raffle.enterRaffle(); // Assert
    }

    function test_RaffleRecordsPlayers_WhenTheyEnter() public {
        vm.prank(s_alice); // Arrange
        s_raffle.enterRaffle{value: s_raffleEntranceFee}(); // Act
        assertEq(s_raffle.getPlayerAddress(0), s_alice); // Assert
    }

    /**
     * `expectEmit` takes the first three parameters as the indexed parameters
     * Since there is only one indexed parameter in `NewPlayerHasEnteredRaffle`,
     * only the first param is `true`, the 2nd, 3rd and the 4th (non-indexed)
     * are false. The last param indicates which contract emitted the event.
     */
    function test_RaffleEmitsEvent_WhenPlayerEnters() public {
        vm.prank(s_alice); // Arrange
        vm.expectEmit(true, false, false, false, address(s_raffle)); // Act
        emit Raffle.NewPlayerHasEnteredRaffle(s_alice);
        s_raffle.enterRaffle{value: s_raffleEntranceFee}(); // Assert
    }

    /**
     * This test simulates calling the `performUpkeep` function to put the Raffle
     * state to `CALCULATING`, so that new players cannot enter while in that state.
     * First, we ensure that `checkUpkeep` conditions are met:
     * First, warp the current `block.timestamp` to a future value of
     * `block.timestamp + s_lotteryDurationSeconds + 1` so that the condition
     * for `timeHasPassed` is guaranteed to be met with 1 additional second:
     * timeHasPassed = block.timestamp + s_lotteryDurationSeconds + 1 - block.timestamp
     *               = s_lotteryDurationSeconds + 1 >= s_lotteryDurationSeconds
     *               = true
     * Also, simulate forwarding the block number by 1 with `vm.roll`.
     */
    function test_PlayerCannotEnterRaffle_WhenRaffleStateIsCalculating() public {
        // Arrange
        vm.prank(s_alice);
        s_raffle.enterRaffle{value: s_raffleEntranceFee}(); // We have entered the raffle,
        vm.warp(block.timestamp + s_lotteryDurationSeconds + 1); // time has passed,
        vm.roll(block.number + 1); // and the block has been incremented.
        s_raffle.performUpkeep(""); // Now, perform upkeep to set the Raffle state to CALCULATING

        // Act
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(s_alice);

        // Assert
        s_raffle.enterRaffle{value: s_raffleEntranceFee}();
    }
}
