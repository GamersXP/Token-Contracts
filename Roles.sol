// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract Roles is AccessControlUpgradeable {
    bytes32 internal constant PAUSER_ROLE = keccak256("PS");
    bytes32 internal constant DAILY_OPERATIONS_ROLE = keccak256("DP");
}
