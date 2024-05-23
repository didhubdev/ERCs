// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


/**
 * @notice The Distributor interface dictates how the holder of any ERC721 compliant tokens, both external
 * and internal to the contract, to create editions that collectors can conditionally mint child tokens from. 
 * External token holders can use the registerOrigin function to register the ERC721 compliant token with the contract. 
 * This function will generate a unique identifier for the external token, which can be used as a proxy to 
 * invoke contract functions under the same interface as internal tokens.
 * 
 * Parent token holders can use the setEdition to specify the condition for minting an edition of the parent token. 
 * An edition is defined by a tokenId of the parent token, the attribute of the child tokens, the address of the 
 * validator contract that specifies the rules to obtain the child token, and the data to initialize these rules.
 *   
 * A Collector can mint a child token of an Edition given that the rules specified by the Validator are 
 * fulfilled.
 *
 * Parent tokens holder can set multiple different editions, each with a different set of rules, and a 
 * different set of attributes that the token holder will be empowered with after the minting of the token.
 */
interface IDistributor {

    /**
     * @dev Emitted when an origin is set
     */
    event RegisterOrigin(address tokenContract, uint256 tokenId, uint256 uniqueIdentifier);
    
    /**
     * @dev Emitted when an edition is created
     * 
     * @param editionHash The hash of the edition configuration
     * @param tokenId The token id of the NFT descriptor
     * @param validator The address of the validator contract
     * @param attribute The functions that will be permitted.
     */
    event SetEdition(bytes32 editionHash, uint256 tokenId, address validator, uint96 attribute);
    
    /**
     * @dev Emitted when an edition is paused
     * 
     * @param editionHash The hash of the edition configuration
     * @param isPaused The state of the edition
     */
    event PauseEdition(bytes32 editionHash, bool isPaused);

    /**
     * @dev Generates a unique identifier with the token for edition, the entry point
     */
    function registerOrigin (address tokenContract, uint256 tokenId, bytes memory data) external;

    /**
     * @dev The parent token holder can set an edition that enables others
     * to mint child tokens given that they fulfill the given rules
     *
     * @param tokenId the token id of the NFT descriptor
     * @param validator the address of the validator contract
     * @param attribute the attribute of the child token.
     * @param ruleInitData the data to be input into the validator contract for seting up the rules
     * 
     * @return editionHash Returns the hash of the edition configuration 
     */
    function setEdition(
        uint256 tokenId,
        address validator,
        uint96  attribute,
        bytes calldata ruleInitData
    ) external returns (bytes32 editionHash);
    
    /**
     * @dev The parent token holder can pause the edition
     *
     * @param editionHash the hash of the edition
     * @param isPaused the state of the edition
     */ 
    function pauseEdition(
        bytes32 editionHash,
        bool isPaused
    ) external;

}