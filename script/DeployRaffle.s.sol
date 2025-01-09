// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console2 as console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "script/interactions/CreateSubscription.s.sol";

contract DeployRaffle is Script {
    constructor() {}

    /**
     * This function handles the deployment process. If the deployment is local,
     * then the mocks (VRF) are deployed first, then the local config is
     * retrieved. If deploying on Sepolia, retrieve the Sepolia network config.
     * @return Raffle
     * @return HelperConfig
     */
    function deployRaffleContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        // Create a subscription if it doesn't exist, i.e. if subscriptionId is 0
        if (networkConfig.subscriptionId == 0) {
            CreateSubscription subscriptionCreator = new CreateSubscription();
            (networkConfig.subscriptionId, networkConfig.vrfCoordinator) =
                subscriptionCreator.callCreateSubscription(networkConfig.vrfCoordinator);
        }

        vm.startBroadcast(); // Start transactions by deploying the Raffle
        Raffle raffle = new Raffle(
            networkConfig.raffleEntranceFee,
            networkConfig.lotteryDurationSeconds,
            networkConfig.keyHash,
            networkConfig.subscriptionId,
            networkConfig.callbackGasLimit,
            networkConfig.enableNativePayment,
            networkConfig.vrfCoordinator
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }

    function run() external {
        deployRaffleContract();
    }
}
