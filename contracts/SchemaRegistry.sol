// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { ISchemaResolver } from "./resolver/ISchemaResolver.sol";

import { EMPTY_UID } from "./Common.sol";
import { Semver } from "./Semver.sol";
import { ISchemaRegistry, SchemaRecord, ClaimType } from "./ISchemaRegistry.sol";

/// @title SchemaRegistry
/// @notice The global schema registry.
contract SchemaRegistry is ISchemaRegistry, Semver {
    error AlreadyExists();

    // The global mapping between schema records and their IDs.
    mapping(bytes32 uid => SchemaRecord schemaRecord) private _registry;

    // The global mapping between schema records and their IDs.
    mapping(bytes32 uid => ClaimType[] claims) private schemaClaims;

    /// @dev Creates a new SchemaRegistry instance.
    constructor() Semver(1, 3, 0) {}

    /// @inheritdoc ISchemaRegistry
    function register(string calldata schema, ClaimType[] calldata claimTypes, ISchemaResolver resolver, bool revocable) external returns (bytes32) {
        SchemaRecord memory schemaRecord = SchemaRecord({
            uid: EMPTY_UID,
            schema: schema,
            resolver: resolver,
            revocable: revocable
        });

        bytes32 uid = _getUID(schemaRecord);
        if (_registry[uid].uid != EMPTY_UID) {
            revert AlreadyExists();
        }

        schemaRecord.uid = uid;
        _registry[uid] = schemaRecord;

        for (uint256 i = 0; i < claimTypes.length; i++) {
            schemaClaims[uid].push(claimTypes[i]);
        }

        emit Registered(uid, msg.sender, schemaRecord);

        return uid;
    }

    /// @inheritdoc ISchemaRegistry
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory) {
        return _registry[uid];
    }

    /// @inheritdoc ISchemaRegistry
    function getSchemaClaims(bytes32 uid) external view returns (ClaimType[] memory) {
        return schemaClaims[uid];
    }

    /// @dev Calculates a UID for a given schema.
    /// @param schemaRecord The input schema.
    /// @return schema UID.
    function _getUID(SchemaRecord memory schemaRecord) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(schemaRecord.schema, schemaRecord.resolver, schemaRecord.revocable));
    }
}
