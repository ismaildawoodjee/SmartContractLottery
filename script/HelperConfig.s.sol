// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console2 as console} from "forge-std/Script.sol";
import {CodeConstants} from "script/CodeConstants.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

/**
 * This contract helps set up the configuration for deploying the main contract.
 */
contract HelperConfig is Script, CodeConstants {
    /* TYPE DECLARATIONS */
    /**
     * A network refers to a specific instance or deployment of a blockchain.
     * Define a struct that holds network-specific information.
     * This struct will have all the parameters that the Raffle constructor
     * needs so that the Raffle contract can be deployed programmatically.
     */
    struct NetworkConfig {
        uint256 raffleEntranceFee;
        uint256 lotteryDurationSeconds;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        bool enableNativePayment;
        address vrfCoordinator;
    }

    /* STATE VARIABLES */
    NetworkConfig public s_activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) s_chainIdToNetworkConfig;

    /* ERRORS */
    error HelperConfig__InvalidChainId(uint256 chainId);

    /* CONSTRUCTOR */
    constructor() {
        s_chainIdToNetworkConfig[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    /* FUNCTIONS */
    /**
     * This function fetches the appropriate network configuration based on the
     * chain ID. We first verify if the VRF Coordinator exists.
     * @param chainId Chain ID of the network we'll be deploying on
     * @return NetworkConfig Network configuration of the specified chain
     */
    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        // if a chain is already deployed (address is not null), get it
        if (s_chainIdToNetworkConfig[chainId].vrfCoordinator != address(0)) {
            return s_chainIdToNetworkConfig[chainId];
        }
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        }
        revert HelperConfig__InvalidChainId(chainId);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            raffleEntranceFee: 0.01 ether,
            lotteryDurationSeconds: 30,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 45774321620783263106425965210246629145291358106998373738980325117999391332166,
            callbackGasLimit: 500_000, // 500,000 units of gas
            enableNativePayment: false, // use `false` to pay with LINK
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check to see if we already have an active local network configuration
        if (s_activeNetworkConfig.vrfCoordinator != address(0)) {
            return s_activeNetworkConfig;
        }
        // Otherwise, deploy a mock VRF Coordinator and return the config
        vm.startBroadcast();

        /**
         * To deploy a mock VRF Coordinator, we need three parameters:
         * @param _baseFee flat fee that VRF charges for the provided randomness
         * @param _gasPrice gas consumed by the VRF node when calling your function
         * @param _weiPerUnitPrice price of a LINK token in Wei units
         */
        VRFCoordinatorV2_5Mock vrfCoordinatorMock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        vm.stopBroadcast();

        s_activeNetworkConfig = NetworkConfig({
            raffleEntranceFee: 0.01 ether,
            lotteryDurationSeconds: 30,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0, // might have to fix this
            callbackGasLimit: 500_000, // 500,000 units of gas
            enableNativePayment: false, // use `false` to pay with LINK
            vrfCoordinator: address(vrfCoordinatorMock)
        });
        return s_activeNetworkConfig;
    }

    function getConfig() external returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
}
