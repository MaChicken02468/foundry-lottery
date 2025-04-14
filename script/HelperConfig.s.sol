// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkTocken.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        bytes32 gasLane;
        uint256 subscriptionId;
        address vrfCoordinator;
        uint32 callbackGasLimit;
        address linkToken;
        uint256 deployKey;
    }

    uint256 public constant DEFAULT_ANVIL_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaVrfConfig();
        } else if (block.chainid == 31337) {
            activeNetworkConfig = getLocalVrfConfig();
        } else {
            revert("Network not supported");
        }
    }

    function getSepoliaVrfConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 9472620989042155549074799988159793928914457263531660127376214684360832966275,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                interval: 30,
                callbackGasLimit: 500000,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                deployKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getLocalVrfConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9; // 0.000000001 LINK per gas

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            baseFee,
            gasPriceLink,
            1e18
        );
        vm.stopBroadcast();

        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0,
                vrfCoordinator: address(vrfCoordinator),
                interval: 30,
                callbackGasLimit: 500000,
                linkToken: address(new LinkToken()),
                deployKey: DEFAULT_ANVIL_KEY
            });
    }
}
