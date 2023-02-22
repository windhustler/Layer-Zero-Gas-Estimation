// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {ILayerZeroEndpoint} from "layerzero/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroUltraLightNodeV2} from "layerzero/interfaces/ILayerZeroUltraLightNodeV2.sol";

interface ILayerZeroRelayerV2Viewer {
    function dstPriceLookup(uint16 chainId) external view returns (uint128 dstPriceRatio, uint128 dstGasPriceInWei);
}

library GasEstimation {
    /// @notice Multiplier for price ratio
    uint256 internal constant LZ_PRICE_RATIO_MULTIPLIER = 1e10;

    struct GasEstimationData {
        ILayerZeroEndpoint lzEndpoint;
        uint16 homeChainId;
        uint16 remoteChainId;
        uint24 callbackGas;
        uint24 remoteGas;
        bytes callbackPayload;
        bytes remotePayload;
        address addressOnDst;
    }

    function estimate(GasEstimationData calldata data)
    external
    view
    returns (uint256 totalFee, bytes memory adapterParams)
    {
        // Gas amount to be airdropped on the remote chain,
        // and will be used to cover the callback on the home chain.
        (uint256 callbackFee,) = data.lzEndpoint.estimateFees(
            data.homeChainId,
            msg.sender,
            data.callbackPayload,
            false,
            abi.encodePacked(uint16(1), uint256(data.callbackGas))
        );

        // Fee required for executing the logic on the remote chain
        (uint256 remoteFee,) = data.lzEndpoint.estimateFees(
            data.remoteChainId,
            msg.sender,
            data.remotePayload,
            false,
            abi.encodePacked(uint16(1), uint256(data.remoteGas))
        );

        // Total fee in native gas token
        totalFee = callbackFee + remoteFee;

        ILayerZeroUltraLightNodeV2 node =
        ILayerZeroUltraLightNodeV2((data.lzEndpoint).getSendLibraryAddress(address(this)));
        ILayerZeroUltraLightNodeV2.ApplicationConfiguration memory config =
        node.getAppConfig(data.remoteChainId, address(this));
        //@todo investigate why dstPriceLookup is not a part of the interface
        (uint256 dstPriceRatio,) = ILayerZeroRelayerV2Viewer(config.relayer).dstPriceLookup(data.remoteChainId);

        adapterParams = abi.encodePacked(
            uint16(2),
            uint256(data.remoteGas),
            callbackFee * LZ_PRICE_RATIO_MULTIPLIER / dstPriceRatio,
            data.addressOnDst
        );
    }
}
