// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice The Origin interface is an optional interface. External token holders can use the registerOrigin function to register the ERC721 compliant token with the contract. This function will generate a unique tokenId for the external token, which can be used as a proxy to invoke contract functions under the same interface as internal tokens. Implementation should take extra care to ensure that the unique identifier is unique across all external and internal tokens.
 */
interface IOrigin {

    /**
     * @dev Emitted when an origin is set
     * 
     * @param tokenContract The address of the external token contract
     * @param externalTokenId The token id of the external token
     * @param tokenId The unique identifier generated for the external token
     */
    event RegisterOrigin(address tokenContract, uint256 externalTokenId, uint256 tokenId);
    
    /**
     * @dev Generates a unique identifier with the token for edition, the entry point
     * 
     * @param tokenContract The address of the external token contract
     * @param externalTokenId The token id of the external token
     * 
     * @return tokenId Returns the unique identifier generated for the external token
     */
    function registerOrigin (address tokenContract, uint256 externalTokenId) external returns (uint256 tokenId);

}
