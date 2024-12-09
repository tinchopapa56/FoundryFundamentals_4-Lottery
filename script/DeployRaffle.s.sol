// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {

    function run() public {
        vm.startBroadcast();

        vm.stopBroadcast();
    }
    function deployContract() public returns(Raffle, HelperConfig){
        HelperConfig helperconfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();

        console.log("DeployRaffle.deployContract(): ", config.subscriptionId);

        if (config.subscriptionId == 0){
            //1. Create sub
            CreateSubscription createSubscriptionScript = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinatorV2) = createSubscriptionScript.createSubscription(config.vrfCoordinatorV2);
            //2. Fund
            FundSubscription fundSub = new FundSubscription();
            fundSub.fundSubscription(config.vrfCoordinatorV2, config.subscriptionId, config.link);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.subscriptionId,
            config.gasLane,
            config.interval,
            config.entranceFee,
            config.callbackGasLimit,
            config.vrfCoordinatorV2
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinatorV2, config.subscriptionId);

        return (raffle, helperconfig);
    }
}
