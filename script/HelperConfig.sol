// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2_5Mock.sol";
//x ahi no funca ese mock

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 1115511;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script{

    error HelperConfig__InvalidChainid();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor(){
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
        bool hasVrfCoord = networkConfigs[chainId].vrfCoordinator != address(0);
        bool isTestingChain = chainId == LOCAL_CHAIN_ID;

        if(hasVrfCoord){
            return networkConfigs[chainId];
        } else if(isTestingChain){
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainid();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee: 0.0001 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 69563845343696194848808305580506156495437382575977282805424587672873219106065,
            callbackGasLimit: 500000
        });
    }
    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory) {
        bool localChainAlreadyRunning = localNetworkConfig.vrfCoordinator != address(0);
        if(localChainAlreadyRunning) {
            return localNetworkConfig;
        }
    }
}