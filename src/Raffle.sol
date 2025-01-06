// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author Ismail Dawoodjee
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5 (Verifiable Random Function)
 */
contract Raffle is VRFConsumerBaseV2Plus {
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
    uint256 private s_lastRecordedTimeStamp; // The last timestamp that was recorded
    address payable[] private s_listOfPlayers; // List of players that entered the raffle - initialized to empty array

    /* EVENTS */
    event NewPlayerHasEnteredRaffle(address indexed _newPlayer);

    /* ERRORS */
    error Raffle__NotEnoughEthToEnterRaffle();

    /* CONSTRUCTOR */
    /**
     * Inherits from VRFConsumerBaseV2Plus, which has its own constructor, so we need to implement its parameters too
     * @param _vrfCoordinator address of VRFCoordinator contract
     * We pass this parameter _vrfCoordinator from Raffle contract's constructor to VRFConsumerBaseV2Plus's constructor.
     * This way we also inherit the s_vrfCoordinator variable
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
        s_lastRecordedTimeStamp = block.timestamp; // Initialized to when the contract is first deployed (first block)
    }

    /* FUNCTIONS */
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
        //! I DONT LIKE THE WAY THIS FUNCTION DOES A LOT OF THINGS - refactor
        // We want to check to see if enough time has passed before picking the winner
        if (block.timestamp - s_lastRecordedTimeStamp > i_lotteryDurationSeconds) {
            revert();
        }
        // This is a request struct type that the `requestRandomWords` needs to get a requestId
        // This struct is defined in the `VRFV2PlusClient` library
        /**
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
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {}

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
