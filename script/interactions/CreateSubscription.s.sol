// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console2 as console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function run() public returns (uint256) {
        return createSubscriptionUsingConfig();
    }

    // This will programmatically call the createSubscription() function
    // using the HelperConfig and whatever parameters are there
    function createSubscriptionUsingConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subscriptionId,) = callCreateSubscription(vrfCoordinator);
        return subscriptionId;
    }

    // This is more specific, where we can provide our own vrfCoordinator
    function callCreateSubscription(address _vrfCoordinator) public returns (uint256, address) {
        // Start of a transaction where we create a subscription on Chainlink
        // and the Metamask wallet opens up to confirm the creation of a subscription
        vm.startBroadcast();
        // For Fork-URL: subscription owner is the Metamask wallet that creates the subscription
        // For local deployment: subscription owner is Foundry default address
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription();
        (,,, address subscriptionOwner,) = VRFCoordinatorV2_5Mock(_vrfCoordinator).getSubscription(subscriptionId);
        console.log("[INFO] [CreateSubscription::callCreateSubscription] Subscription owner is:", subscriptionOwner);
        vm.stopBroadcast();

        return (subscriptionId, _vrfCoordinator); //? why return vrfCoordinator
    }
}
