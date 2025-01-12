// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console2 as console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "script/interactions/CreateSubscription.s.sol";
import {FundSubscription} from "script/interactions/FundSubscription.s.sol";
import {AddConsumer} from "script/interactions/AddConsumer.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployRaffle is Script {
    function run() public {
        deployRaffleContract();
    }

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

        // Fund the subscription that was just created
        FundSubscription subscriptionFunder = new FundSubscription();
        subscriptionFunder.callFundSubscription(
            networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.linkTokenAddress
        );

        // Before adding the Raffle contract as a consumer, we need to deploy it first
        // Start a transaction to deploy the Raffle contract
        (,,, address subscriptionOwner,) =
            VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinator).getSubscription(networkConfig.subscriptionId);
        console.log("[INFO] [DeployRaffle::deployRaffleContract] Subscription owner is:", subscriptionOwner);
        vm.startBroadcast(subscriptionOwner);
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

        // Add a consumer (Raffle contract) to the funded subscription
        AddConsumer consumerAdder = new AddConsumer();
        consumerAdder.callAddConsumer(address(raffle), networkConfig.vrfCoordinator, networkConfig.subscriptionId);

        return (raffle, helperConfig);
    }
}
