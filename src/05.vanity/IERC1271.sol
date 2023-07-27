// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    
    // 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}