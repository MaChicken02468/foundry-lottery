// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkTocken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , address vrfCoordinator, , , uint256 deployKey) = helperConfig
            .activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployKey);
    }

    function createSubscription(
        address vrfCoordinator,
        uint256 deployKey
    ) public returns (uint256) {
        vm.startBroadcast(deployKey);

        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        return subId;
    }

    function run() external returns (uint256) {
        uint256 subId = createSubscriptionUsingConfig();
        console.log("Subscription ID: ", subId);
        return subId;
    }
}

contract FundSubscription is Script {
    uint96 public constant BASE_FEE = 1.25 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            ,
            uint256 subId,
            address vrfCoordinator,
            ,
            address linkToken,
            uint256 deployKey
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, linkToken, deployKey);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subId,
        address linkToken,
        uint256 deployKey
    ) public {
        console.log("Funding subscription...", subId);
        console.log("VRF Coordinator address: ", vrfCoordinator);
        console.log("on ChainId: ", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast(deployKey);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subId,
                BASE_FEE
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                BASE_FEE,
                abi.encode(subId)
            );
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address raffleConfig) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            ,
            uint256 subId,
            address vrfCoordinator,
            ,
            ,
            uint256 deployKey
        ) = helperConfig.activeNetworkConfig();
        addConsumer(vrfCoordinator, subId, raffleConfig, deployKey);
    }

    function addConsumer(
        address vrfCoordinator,
        uint256 subId,
        address raffleConfig,
        uint256 deployKey
    ) public {
        console.log("Adding consumer to subscription...", subId);
        console.log("VRF Coordinator address: ", vrfCoordinator);
        console.log("on ChainId: ", block.chainid);

        vm.startBroadcast(deployKey);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, raffleConfig);
        vm.stopBroadcast();
    }

    function run() external {
        address contractAddress = DevOpsTools.get_most_recent_deployment(
            "MyContract",
            block.chainid
        );
        addConsumerUsingConfig(contractAddress);
    }
}
