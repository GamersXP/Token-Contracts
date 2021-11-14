// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Schemes {
    using Counters for Counters.Counter;

    event SchemeAdded(
        uint256 schemeId,
        uint8 schemeType,
        uint256 schemeValue,
        uint256 purchaseAmount,
        uint256 validThru,
        uint16 expirationDays
    );
    event SchemeUpdated(
        uint256 schemeId,
        uint8 schemeType,
        uint256 schemeValue,
        uint256 purchaseAmount,
        uint256 validThru,
        uint16 expirationDays
    );
    event SchemeAssigned(
        address indexed player,
        uint256 schemeId,
        uint256 purchasedDate,
        uint16 expirationDays
    );

    uint8 public constant ADDITION_SCHEME = 1;
    uint8 public constant PERCENTAGE_SCHEME = 2;
    uint8 public constant MULTIPLIER_SCHEME = 3;
    uint8 public constant SERVICES_SCHEME = 4;

    Counters.Counter private _schemeId;

    struct Scheme {
        uint256 schemeId;
        uint8 schemeType;
        uint256 schemeValue;
        uint256 purchaseAmount;
        uint256 validThru;
        uint16 expirationDays;
    }

    struct Assigned {
        uint256 schemeId;
        bool isAssigned;
        uint256 purchasedDate;
    }

    mapping(uint256 => Scheme) public schemes;
    mapping(address => Assigned[]) internal assignedSchemes;

    function _isValidBuyTransaction(uint256 schemeId, uint256 userTokenBalance)
        internal
        view
    {
        require(schemes[schemeId].validThru != 0, "Scheme: not found");
        require(
            userTokenBalance >= schemes[schemeId].purchaseAmount,
            "Scheme: invalid transaction"
        );

        for (
            uint256 index = 0;
            index < assignedSchemes[msg.sender].length;
            index++
        ) {
            if (assignedSchemes[msg.sender][index].schemeId == schemeId) {
                require(
                    !assignedSchemes[msg.sender][schemeId].isAssigned,
                    "Scheme: already assigned"
                );
            }
        }
    }

    function _addScheme(
        uint8 schemeType,
        uint256 schemeValue,
        uint256 purchaseAmount,
        uint256 validThru,
        uint16 expirationDays
    ) internal returns (uint256) {
        require(schemeValue > 0, "Scheme: value should not be 0");

        require(
            schemeType == ADDITION_SCHEME ||
                schemeType == PERCENTAGE_SCHEME ||
                schemeType == MULTIPLIER_SCHEME ||
                schemeType == SERVICES_SCHEME,
            "Scheme:invalid"
        );
        uint256 currentId = _schemeId.current();
        schemes[currentId].schemeId = currentId;
        schemes[currentId].schemeType = schemeType;
        schemes[currentId].schemeValue = schemeValue;
        schemes[currentId].purchaseAmount = purchaseAmount;
        schemes[currentId].validThru = validThru;
        schemes[currentId].expirationDays = expirationDays;
        _schemeId.increment();

        emit SchemeAdded(
            currentId,
            schemeType,
            schemeValue,
            purchaseAmount,
            validThru,
            expirationDays
        );
        return currentId;
    }

    function getScheme(uint256 id) public view returns (Scheme memory) {
        return (schemes[id]);
    }

    function getSchemesFromUser(address from)
        public
        view
        returns (Assigned[] memory)
    {
        return assignedSchemes[from];
    }

    function _updateScheme(
        uint256 id,
        uint8 schemeType,
        uint256 schemeValue,
        uint256 purchaseAmount,
        uint256 validThru,
        uint16 expirationDays
    ) internal {
        require(schemes[id].validThru != 0, "Scheme: not found");
        schemes[id].schemeType = schemeType;
        schemes[id].schemeValue = schemeValue;
        schemes[id].purchaseAmount = purchaseAmount;
        schemes[id].validThru = validThru;
        schemes[id].expirationDays = expirationDays;

        emit SchemeUpdated(
            id,
            schemeType,
            schemeValue,
            purchaseAmount,
            validThru,
            expirationDays
        );
    }

    function _assignScheme(address player, uint256 schemeId) internal {
        uint256 timestamp = block.timestamp;
        uint16 expirationDays = schemes[schemeId].expirationDays;

        Assigned memory assignedScheme = Assigned(schemeId, true, timestamp);
        assignedSchemes[player].push(assignedScheme);

        emit SchemeAssigned(player, schemeId, timestamp, expirationDays);
    }

    function getSchemes() public view returns (Scheme[] memory) {
        Scheme[] memory _mscheme = new Scheme[](_schemeId.current());
        for (uint256 index = 0; index < _schemeId.current(); index++) {
            _mscheme[index] = schemes[index];
        }
        return _mscheme;
    }
}
