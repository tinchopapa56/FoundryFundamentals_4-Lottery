// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LINK_MOCK} from "test/mocks/LINK_MOCK.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";


contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.automationUpdateInterval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        // assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }
    /*//////////////////////////////////////////////////////////////
                            ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/
    function test_RaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreEthToEnterRaffle.selector);
        raffle.enterRaffle();
    }
    function test_RaffleRecordsPlayerWhentheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }
    // function test_EmitsEventOnEntrance() public {
    //     vm.prank(PLAYER);
    //     vm.recordLogs();

    //     vm.expectEmit(true, false, false, false, address(raffle));
    //     // emit RaffleEnter(PLAYER);

    //     raffle.enterRaffle{value: entranceFee}();
    // }
    function test_DontAllowPlayersToEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // raffle.performUpkeep("");
        raffle.pickWinner();

        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
}
