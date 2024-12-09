// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
// import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LINK_MOCK} from "test/mocks/LINK_MOCK.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoord = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoord);
        return (subId, vrfCoord);
    }
    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256, address) {
        console.log("creating sub on chain id: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console.log("Your sub id is: ", subId);
        console.log("please update the subId in your HelperConfi.sol");
        return (subId, vrfCoordinator);
    }

    function run() public {
        vm.startBroadcast();
        createSubscriptionUsingConfig();
        vm.stopBroadcast();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // == 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoord = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkTokenMOCK = helperConfig.getConfig().link; 
        fundSubscription(vrfCoord, subscriptionId, linkTokenMOCK);
    }
    function fundSubscription(address vrfCoordinator, uint256 subId, address linkToken) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoord: ", vrfCoordinator);
        console.log("on chainId: ", block.chainid);

        bool isLocalChain = block.chainid == LOCAL_CHAIN_ID;
        if(isLocalChain){
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            //eth sepolia
            vm.startBroadcast();
            LINK_MOCK(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
        console.log("fundSubscription was a SUCCESS");

    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function run() public {
        
    }
}