// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

/*

EHHHHHHHHHHHHHHHHH
REMIXXXXX
    0.01, 
    86400, 
    "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625",
    "0x040c7405d5b1cfe7852b45ad79be22d3ec6002b478286eac55e39a59babc3bb7", 
    69563845343696194848808305580506156495437382575977282805424587672873219106065,  
    100000
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
// import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
// import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

// abstract contract Raffle is VRFConsumerBaseV2Plus {
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
    error Raffle__SendMoreEthToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();

    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState; 


    //VRF state variables
    bytes32 private immutable i_keyHash; 
    uint256 private immutable i_subscriptionId; 
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;


    /*
    IVRFCoordinatorV2Plus COORDINATOR;
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625; 
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c; 
    uint32 callbackGasLimit = 2500000; 
    uint16 requestConfirmations = 3; 
    uint32 numWords =  1;
    */

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        //s_vrfCoordinator.requestRandomWords();
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH Sent!");
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreEthToEnterRaffle();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        // 1. Makes migraition easier
        // 2. Makes front end "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    //CEI: Checks - Effects - Interactions
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        //Checks <> requires
        //Effects (internal state)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); 
        s_lastTimeStamp = block.timestamp; 
        emit WinnerPicked(s_recentWinner);

        //Interactions (external)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if(!success) {
            revert Raffle__TransferFailed();
        }
    }

    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        s_raffleState = RaffleState.CALCULATING;

        //1. Request RNGet
        //2. RGet RNG
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash, //gas price
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit, //gas limit
            numWords: NUM_WORDS,
            // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(req);
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
}
