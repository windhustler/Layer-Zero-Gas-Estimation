// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {GasEstimation} from "../src/GasEstimation.sol";

contract GasEstimationMock {
    function estimate(GasEstimation.GasEstimationData calldata data)
        external
        view
        returns (uint256 totalFee, bytes memory adapterParams)
    {
        return GasEstimation.estimate(data);
    }
}
