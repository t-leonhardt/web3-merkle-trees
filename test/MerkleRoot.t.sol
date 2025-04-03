// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {Merkle} from "murky/src/Merkle.sol";

contract CounterTest is Test {

    Whitelist public whitelist;

    //function: encodin leaf nodes
    function encodeLeaf(
        address _address,
        uint64 _spots
    ) public pure returns (bytes32) {
        // using keccak256 as hashing algorithm
        return keccak256(abi.encodePacked(_address, _spots));
    }

    function test_MerkleRoot() public {

        // initialize merkle tree
        Merkle merkle = new Merkle();

        // create array of elements for merkle tree
        bytes32[] memory list = new bytes32[](6);
        list[0] = encodeLeaf(vm.addr(1), 2);
        list[1] = encodeLeaf(vm.addr(2), 2);
        list[2] = encodeLeaf(vm.addr(3), 2);
        list[3] = encodeLeaf(vm.addr(4), 2);
        list[4] = encodeLeaf(vm.addr(5), 2);
        list[5] = encodeLeaf(vm.addr(6), 2);

        // compute merkle root
        bytes32 root = merkle.getRoot(list);

        // deploy whitelist contract
        whitelist = new Whitelist(root);
        
        for (uint8 i = 0; i < 6; i++) {
            bytes32[] memory proof = merkle.getProof(list, i);

            // Impersonate current address cause contract uses `msg.sender` 
            // as 'original value' for the address when verifying the Merkle Proof
            vm.prank(vm.addr(i + 1));


            // Check that contract can verify the presence of address
            // in Merkle Tree using just the Root provided to it
            // By giving it the Merkle Proof and original values, it calculates 
            // `address` using `msg.sender`, and we provide number of NFTs that the address can mint 
            bool verified = whitelist.checkInWhitelist(proof, 2);

            assertEq(verified, true);
        }

        //make an empty bytes32 array as an invalid proof
        bytes32[] memory invalidProof;

        // Check for invalid addresses
        bool verifiedInvalid = whitelist.checkInWhitelist(invalidProof, 2);
        assertEq(verifiedInvalid, false);
    }
}