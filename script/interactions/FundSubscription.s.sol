// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console2 as console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CodeConstants} from "script/CodeConstants.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract FundSubscription is Script, CodeConstants {
    function run() public {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkTokenAddress = helperConfig.getConfig().linkTokenAddress;
        callFundSubscription(vrfCoordinator, subscriptionId, linkTokenAddress);
    }

    function callFundSubscription(address _vrfCoordinator, uint256 _subscriptionId, address _linkTokenAddress) public {
        console.log("Funding subscription:", _subscriptionId);
        console.log("Using vrfCoordinator:", _vrfCoordinator);
        console.log("On chain ID:", block.chainid);

        // This is the start of a transaction, where we fund the subscription
        // that we created, and the Metamask wallet opens up for us to confirm
        // adding funds to the subscription
        vm.startBroadcast();
        if (block.chainid == LOCAL_CHAIN_ID) {
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(_subscriptionId, FUND_AMOUNT);
        } else {
            LinkToken(_linkTokenAddress).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subscriptionId));
        }
        vm.stopBroadcast();
    }
}
