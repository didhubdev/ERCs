// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice This is the validator interface. It specifies the rules that need to be fulfilled and enforces the
 * fulfillment of these rules. The parent token holder is required to first register these rules onto a particular
 * edition, identified by the hash of the edition configuration (editionHash). When a collector wants to invoke a certain
 * action associated with the editionHash, i.e., mint a token from the edition, the collector will need to pass the 
 * validation by successfully calling the validate function.
 * 
 * In the validation process, the collector will need to supply the basic information including the initiator
 * (the address of the collector), editionHash, and some optional fullfilmentData. The validate function 
 * will revert upon error, and will return nothing if the validation is successful.
 */
interface IValidator {

    /**
     * @dev Sets up the validator rules by the edition hash and the data for initialization. This function will
     * decode the data back to the required parameters and sets up the rules that decides who can or cannot
     * invoke a particular action.
     *
     * @param editionHash The hash of the edition configuration
     * @param ruleInitData The data bytes for initializing the validation rules. Parameters are encoded into bytes
     */
    function setRules(
        bytes32 editionHash,
        bytes calldata ruleInitData
    ) external;

    /**
     * @dev Supply the data that will be used to validate the fulfilment of the rules setup by the parent token holder.
     *
     * @param initiator the party who initiate vadiation
     * @param editionHash the hash of the edition configuration
     * @param actionType the type of action to validation
     * @param fullfilmentData the addtion data that is required for passing the validator rules
     */
    function validate(
        address initiator,
        bytes32 editionHash,
        uint256 actionType,
        bytes calldata fullfilmentData
    ) external payable;
    
}