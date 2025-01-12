// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console2 as console} from "forge-std/Script.sol";
import {DevOpsTools} from "@foundry-devops/src/DevOpsTools.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

/**
 * @dev The consumer is going to be the most recently deployed Raffle contract
 */
contract AddConsumer is Script {
    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }

    function addConsumerUsingConfig(address _mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        callAddConsumer(_mostRecentlyDeployed, vrfCoordinator, subscriptionId);
    }

    function callAddConsumer(address _contractToAddToVRF, address _vrfCoordinator, uint256 _subscriptionId) public {
        // Only the subscription owner can add a consumer
        // Testing on --fork-url fails because the address calling the `addConsumer`
        // function is not the subscription owner. Get the subscription owner by
        // calling the `getSubscription` function from VRFCoordinator
        (,,, address subscriptionOwner,) = VRFCoordinatorV2_5Mock(_vrfCoordinator).getSubscription(_subscriptionId);
        console.log("[INFO] [AddConsumer::callAddConsumer] Subscription owner is:", subscriptionOwner);
        vm.startBroadcast(subscriptionOwner);
        VRFCoordinatorV2_5Mock(_vrfCoordinator).addConsumer(_subscriptionId, _contractToAddToVRF);
        vm.stopBroadcast();
    }
}
