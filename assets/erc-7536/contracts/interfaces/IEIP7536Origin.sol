// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice The Origin interface is an optional interface.
 * External token holders can use the registerOrigin function to register the ERC721 compliant token with the contract. 
 * This function will generate a unique identifier for the external token, which can be used as a proxy to 
 * invoke contract functions under the same interface as internal tokens. Implementation should take extra care
 * to ensure that the unique identifier is unique across all external and internal tokens.
 */
interface IOrigin {

    /**
     * @dev Emitted when an origin is set
     * 
     * @param tokenContract The address of the external token contract
     * @param tokenId The token id of the external token
     * @param uniqueIdentifier The unique identifier generated for the external token
     */
    event RegisterOrigin(address tokenContract, uint256 tokenId, uint256 uniqueIdentifier);
    
    /**
     * @dev Generates a unique identifier with the token for edition, the entry point
     * 
     * @param tokenContract The address of the external token contract
     * @param tokenId The token id of the external token
     * @param data The data to be input into the contract for setting up the rules
     * 
     * @return uniqueIdentifier Returns the unique identifier generated for the external token
     */
    function registerOrigin (address tokenContract, uint256 tokenId, bytes memory data) external returns (uint256 uniqueIdentifier);

}
