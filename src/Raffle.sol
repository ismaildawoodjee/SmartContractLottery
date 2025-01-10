// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {console2 as console} from "forge-std/Script.sol";

/**
 * @title A sample Raffle contract
 * @author Ismail Dawoodjee
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5 (Verifiable Random Function)
 */
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* TYPE DECLARATIONS */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* CONSTANTS */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /* IMMUTABLES */
    uint256 private immutable i_raffleEntranceFee; // Entrance fee for entering the raffle
    uint256 private immutable i_lotteryDurationSeconds; // How long each round of lottery lasts before picking a winner
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    bool private immutable i_enableNativePayment; // usually `false`, to pay in LINK

    /* STATE VARIABLES */
    uint256 private s_lastRecordedTimestamp; // The last timestamp that was recorded
    address payable private s_recentRaffleWinner; // Most recent winner of the raffle
    RaffleState private s_raffleState; // Current state of the Raffle, whether its OPEN or other states
    address payable[] private s_listOfPlayers; // List of players that entered the raffle - initialized to empty array

    /* EVENTS */
    event NewPlayerHasEnteredRaffle(address indexed _newPlayer);
    event RaffleWinnerPicked(address indexed _raffleWinner);
    event RandomWordRequested(uint256 indexed _requestId);

    /* ERRORS */
    error Raffle__NotEnoughEthToEnterRaffle();
    error Raffle__FailedToSendRafflePrizeToWinner();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 _raffleBalance, uint256 _numPlayersInRaffle, RaffleState _raffleState);

    /* CONSTRUCTOR */
    /**
     * Inherits from VRFConsumerBaseV2Plus, which has its own constructor, so we
     * need to implement its parameters too.
     * @param _vrfCoordinator address of VRFCoordinator contract
     * We pass this parameter _vrfCoordinator from Raffle contract's constructor
     * to VRFConsumerBaseV2Plus's constructor.
     * This way we also inherit the s_vrfCoordinator variable.
     */
    constructor(
        uint256 _raffleEntranceFee,
        uint256 _lotteryDurationSeconds,
        bytes32 _keyHash,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit,
        bool _enableNativePayment,
        address _vrfCoordinator
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_raffleEntranceFee = _raffleEntranceFee;
        i_lotteryDurationSeconds = _lotteryDurationSeconds;
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        i_enableNativePayment = _enableNativePayment;
        s_lastRecordedTimestamp = block.timestamp; // Initialized to when the contract is first deployed (first block)
        s_raffleState = RaffleState.OPEN; // Raffle state should be OPEN when contract is first deployed
    }

    /* FUNCTIONS */
    function enterRaffle() external payable {
        if (msg.value < i_raffleEntranceFee) revert Raffle__NotEnoughEthToEnterRaffle();
        if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();

        s_listOfPlayers.push(payable(msg.sender)); // Player is going to be the address that called this function
        emit NewPlayerHasEnteredRaffle(msg.sender);
    }

    /**
     * This is the function that the Chainlink nodes will call to see when and
     * if the lottery is ready to have a winner picked. The following should be
     * true in order for `upkeepNeeded` to be true:
     * 1. The time interval (lottery duration) has passed between raffle runs
     * 2. The lottery is open (RaffleState is OPEN)
     * 3. The contract has non-zero ETH (check if players have entered raffle)
     * 4. There are players registered in the raffle
     * 5. Implicitly, the VRF Subscription is funded - has non-zero LINK or ETH
     * @param - //checkData //? `calldata` type cannot be used. Why?
     * @return upkeepNeeded (bool) - true if it's time to restart the lottery
     * By returning `bool upkeepNeeded`, the return variable is already
     * initialized to `false` and we can use it within the function.
     * @return - //performData
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timeHasPassed = ((block.timestamp - s_lastRecordedTimestamp) >= i_lotteryDurationSeconds);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool raffleHasBalance = (address(this).balance > 0);
        bool raffleHasPlayers = (s_listOfPlayers.length > 0);
        upkeepNeeded = (timeHasPassed && isOpen && raffleHasBalance && raffleHasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * `performUpkeep` function, aka, transaction to request a VRF random number
     * 1. This function needs to get a random number from VRF
     * 2. Then it needs to use the random number to pick out a winner
     * 3. Finally, it needs to be called automatically, at periodic intervals
     *
     * Getting a random number is a two-transaction process:
     * 1. First, we send a transaction to request a random number from the subscription
     * 2. In the next transaction, we get that random number from the oracle
     */
    function performUpkeep(bytes calldata /* performData */ ) external override {
        // If all conditions are met to perform upkeep, execute this function
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_listOfPlayers.length, s_raffleState);
        }
        s_raffleState = RaffleState.CALCULATING; // Can also be RaffleState(1), when picking out the winner

        /**
         * This is a request struct type that the `requestRandomWords` needs to get a requestId.
         * This struct is defined in the `VRFV2PlusClient` library.
         * @param keyHash: Gas lane key hash value - the maximum gas price you're willing to pay for a request in wei.
         * @param subId: The subscription ID that this contract uses for funding requests.
         * @param requestConfirmations: How many confirmations the Chainlink node should wait before responding.
         * @param callbackGasLimit: Max gas to use for callback request to contract's `fulfillRandomWords` function.
         * @param numWords: How many random values to request.
         * @param nativePayment: `true` if payment in native tokens such as ETH, or `false` to pay in LINK
         */
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: i_enableNativePayment}))
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

        // this is redundant because `requestRandomWords` also emits an event
        // with a non-indexed `requestId` parameter
        emit RandomWordRequested(requestId);
    }

    /**
     * This function is going to be called by the VRF service right after the
     * `performUpkeep` function makes a transaction, which requests a random word.
     * @param //requestId - ignored
     * @param _randomWords Use the provided random number to pick a winner
     */
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata _randomWords) internal override {
        console.log("Caller:", address(msg.sender));
        uint256 indexOfWinner = _randomWords[0] % s_listOfPlayers.length;
        address payable raffleWinner = s_listOfPlayers[indexOfWinner];

        s_recentRaffleWinner = raffleWinner;
        s_listOfPlayers = new address payable[](0); // First, reset list of Raffle players.
        s_lastRecordedTimestamp = block.timestamp; // Then, update the last recorded timestamp. Finally, reopen raffle.
        s_raffleState = RaffleState.OPEN; // Reopen Raffle after the winner has been chosen, but before the prize is sent
        emit RaffleWinnerPicked(raffleWinner);

        // Send prize money to raffle winner
        (bool isSuccessfullyCalled,) = raffleWinner.call{value: address(this).balance}("");
        if (!isSuccessfullyCalled) revert Raffle__FailedToSendRafflePrizeToWinner();
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

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getLastRecordedTimestamp() external view returns (uint256) {
        return s_lastRecordedTimestamp;
    }

    function getRecentRaffleWinner() external view returns (address) {
        return s_recentRaffleWinner;
    }
}
