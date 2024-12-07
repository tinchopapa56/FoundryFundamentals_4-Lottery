// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import {LinkToken} from "../test/mocks/LinkToken.sol";
import {Script, console2} from "forge-std/Script.sol";
// import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    /* VRF MOck*/
    uint96 public constant MOCK_BASE_FEE = 0.25 ether; 
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9; 
    //LINK / eth price
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
    /* ENDS VRF MOck*/


    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 1115511;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {

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

    function getConfig()public returns(NetworkConfig meemory){
        getConfigByChainId(block.chainId);
    }

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
        bool hasVrfCoord = networkConfigs[chainId].vrfCoordinator != address(0);
        bool isTestingChain = chainId == LOCAL_CHAIN_ID;

        if(hasVrfCoord){
            return networkConfigs[chainId];
        } else if (isTestingChain) {
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

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfrMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK, 
            MOCK_WEI_PER_UNIT_LINK
        );
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.0001 ether,
            interval: 30,
            vrfCoordinator: address(vrfrMock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 69563845343696194848808305580506156495437382575977282805424587672873219106065,
            callbackGasLimit: 500000
        });
        return localNetworkConfig;
    }
    function getMainnetEthConfig() public pure returns (NetworkConfig memory mainnetNetworkConfig) {
        mainnetNetworkConfig = NetworkConfig({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805,
            automationUpdateInterval: 30, // 30 seconds
            raffleEntranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
    }
}