// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);

    Raffle raffle;
    HelperConfig helperConfig;
    uint256 entranceFee;
    uint256 interval;
    bytes32 gasLane;
    uint256 subscriptionId;
    address vrfCoordinator;
    uint32 callbackGasLimit;
    address linkToken;
    uint256 deployKey;

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    address USER = makeAddr("user");
    address PLAYER1 = makeAddr("player1");
    address PLAYER2 = makeAddr("player2");
    address PLAYER3 = makeAddr("player3");

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        (
            entranceFee,
            interval,
            gasLane,
            subscriptionId,
            vrfCoordinator,
            callbackGasLimit,
            linkToken,
            deployKey
        ) = helperConfig.activeNetworkConfig();

        vm.deal(USER, 10 ether);
    }

    function testRaffleInitialState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /* enterRaffle */
    function testEnterRaffleWithNoMoney() public {
        vm.prank(USER);

        vm.expectRevert(Raffle.Raffle__NotEnoughEth.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayers() public {
        vm.prank(USER);
        raffle.enterRaffle{value: entranceFee}();
        address players = raffle.getPlayers(0);
        assert(players == USER);
    }

    function testRaffleEmitsEventOnEnter() public {
        vm.prank(USER);
        vm.expectEmit(true, false, false, false, address(raffle));

        emit EnteredRaffle(USER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testRaffleDoesNotAllowEntranceWhenRaffleIsCalculating() public {
        vm.prank(USER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(USER);
        raffle.enterRaffle{value: entranceFee}();
    }

    //// checkUpkeep////

    function testCheckUpkeepReturnsFalseIfAndHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public {
        vm.prank(USER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testPerformUpkeepIfCheckUpkeepIsTrue() public {
        vm.prank(USER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        vm.deal(address(raffle), 0);

        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    modifier raffleEnteredAndTimePassed() {
        vm.prank(USER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEnteredAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING);
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEnteredAndTimePassed skipFork {
        vm.expectRevert();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerAndSendsMoneyAndResets()
        public
        raffleEnteredAndTimePassed
        skipFork
    {
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        uint256 previousTimestamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants);

        for (uint256 i = startingIndex; i < additionalEntrants; i++) {
            address player = address(uint160(i));
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        uint256 requestIdUint = uint256(requestId);

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            requestIdUint,
            address(raffle)
        );

        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getLengthOfPlayers() == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(previousTimestamp < raffle.getLastTimeStamp());
        assert(
            raffle.getRecentWinner().balance ==
                STARTING_USER_BALANCE + prize - entranceFee
        );
    }
}
