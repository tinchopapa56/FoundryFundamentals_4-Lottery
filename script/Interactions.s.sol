// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {LINK_MOCK} from "test/mocks/LINK_MOCK.sol";

import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Script, console} from "forge-std/Script.sol";


contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoord = helperConfig.getConfig().vrfCoordinatorV2;
        (uint256 subId, ) = createSubscription(vrfCoord);
        return (subId, vrfCoord);
    }
    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256, address) {
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
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
        address vrfCoord = helperConfig.getConfig().vrfCoordinatorV2;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkTokenMOCK = helperConfig.getConfig().link; 
        fundSubscription(vrfCoord, subscriptionId, linkTokenMOCK);
    }
    function fundSubscription(address vrfCoordinator, uint256 subId, address linkToken) public {
        console.log("Funding subscription: ", subId);
        console.log("To vrfCoord: ", vrfCoordinator);
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

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoord = helperConfig.getConfig().vrfCoordinatorV2;
        addConsumer(mostRecentlyDeployed, vrfCoord, subId);
    }
    function addConsumer(address contractToAddToVRF, address vrfCoordinator, uint256 subId /*, address account*/) public {
        console.log("Adding consumer contract: ", contractToAddToVRF);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);

        //The same as in the official website VrfCoordinator(subId, consumer)
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVRF);
        vm.stopBroadcast();
    }

    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}