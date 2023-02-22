// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {ILayerZeroEndpoint} from "layerzero/interfaces/ILayerZeroEndpoint.sol";
import {GasEstimation, GasEstimationMock} from "./GasEstimationMock.sol";

contract GasEstimationMockTest is Test {
    GasEstimationMock gasEstimationMock;

    string mainnetHttpsUrl;
    uint256 mainnetFork;
    uint256 blockNumber;

    address lzEndpoint = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    uint16 homeChainId = 101;
    uint16 remoteChainId = 106;
    uint24 callbackGas = 350_000;
    uint24 remoteGas = 550_000;
    address addressOnDst = address(0xABCD);

    function setUp() public {
        mainnetHttpsUrl = vm.envString("MAINNET_HTTPS_URL");
        // TODO: change this blockNumber to provoke a revert
        blockNumber = 16_477_598;
        mainnetFork = vm.createSelectFork(mainnetHttpsUrl, blockNumber);
        gasEstimationMock = new GasEstimationMock();
    }

    function testGasEstimation() public {
        bytes memory callbackPayload = getDummyPayload(500);
        bytes memory remotePayload = getDummyPayload(250);

        (uint256 estimatedFee, bytes memory adapterParams) = gasEstimationMock.estimate(
            GasEstimation.GasEstimationData(
                ILayerZeroEndpoint(lzEndpoint),
                homeChainId,
                remoteChainId,
                callbackGas,
                remoteGas,
                callbackPayload,
                remotePayload,
                addressOnDst
            )
        );

        // Fee estimated in steps matches the final estimation which will be passed to the lzSend
        (uint256 expectedFee,) =
            ILayerZeroEndpoint(lzEndpoint).estimateFees(remoteChainId, msg.sender, remotePayload, false, adapterParams);
        int diff = int(estimatedFee) - int(expectedFee);
        console.log("estimatedFee: %s", estimatedFee);
        console.log("expectedFee: %s", expectedFee);
        assertTrue(diff >= -100 && diff <= 100);
    }

    function getDummyPayload(uint256 payloadSize) internal pure returns (bytes memory) {
        bytes memory payload = new bytes(payloadSize);
        for (uint256 i = 0; i < payloadSize; i++) {
            payload[i] = bytes1(uint8(65 + i));
        }
        return payload;
    }
}
