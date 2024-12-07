// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";

contract RaffleScript is Script {

    function run() public {
        vm.startBroadcast();

        vm.stopBroadcast();
    }
    function DeployRaffle() public returns(Raffle, HelperConfig){
        //  uint256 entranceFee,
        // uint256 interval,
        // address vrfCoordinator,
        // bytes32 gasLane,
        // uint256 subscriptionId,
        // uint32 callbackGasLimit
    }
}
