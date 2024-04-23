pragma solidity 0.8.19;

import "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import "forge-std/src/console.sol";
import "../contracts/SchemaRegistry.sol";
import "../contracts/ISchemaRegistry.sol";
import "./utils/Assertions.sol";
import { ISchemaRegistry, SchemaRecord, ClaimType } from "../contracts/ISchemaRegistry.sol";

contract SchemaRegistTest is PRBTest, StdCheats, Assertions {
   
    SchemaRegistry schemaRegistry;
    StdCheats.Account user1;

    event Registered(bytes32 indexed uid, address indexed registerer, SchemaRecord schema);

    // creates a struct containing both a labeled address and the corresponding private key
    function makeAccount(string memory name) internal override returns (Account memory account) {
        (account.addr, account.key) = makeAddrAndKey(name);
    }

    /// @dev Generates a user, labels its address, and funds it with ETH.
    function createUser(string memory name) internal returns (Account memory user) {
        user = makeAccount(name);
        vm.deal({ account: user.addr, newBalance: 100_000 ether });
    }

    function setUp() public {
        user1 = makeAccount("user1");
        schemaRegistry = new SchemaRegistry();
    }

    function test_register_schema() public {
        createUser("user1");

        ClaimType[] memory claimTypes = new ClaimType[](1);

        schemaRegistry.register("schema", claimTypes, ISchemaResolver(address(0)), true);

        //get schemaId from the event emitted
        bytes32 schemaId = keccak256(abi.encodePacked("schema", ISchemaResolver(address(0)), true));

        // Emits Event
        emit Registered(schemaId, user1.addr, SchemaRecord({    
            uid: schemaId,
            schema: "schema",
            resolver: ISchemaResolver(address(0)),
            revocable: true
        }));


        SchemaRecord memory schemaRecord = schemaRegistry.getSchema(keccak256(abi.encodePacked("schema", ISchemaResolver(address(0)), true)));
        assertEq(schemaRecord.schema, "schema");
        assertEq(address(schemaRecord.resolver), address(0));
        assertEq(schemaRecord.revocable, true);
    }

}