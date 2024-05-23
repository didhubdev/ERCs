// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';


import './interfaces/IEIP7536Distributor.sol';
import './interfaces/IEIP7536Validator.sol';

/**
 * @notice This is an implementation of the IDistributor interface.
 */
contract Distributor is ERC721Enumerable, IDistributor {
    using Strings for uint256;

    struct Edition {
        uint256 tokenId;
        address validator;
        uint96  actions;
    }

    struct NFTDescriptor {
        address tokenContract;
        uint256 tokenId;
    }

    uint96 private constant _TRANSFER = 1<<0;  // child action
    uint96 private constant _UPDATE = 1<<1;    // child action
    uint96 private constant _REVOKE = 1<<2;    // parent action
    
    uint256 private _tokenCounter;

    // tokenId => editionHash
    mapping(uint256 => bytes32) private _editionHash;
    mapping(uint256 => string) private _tokenURI;

    // nft descriptor => edition (For Record Keeping, editions cannot be deleted once set)
    mapping(uint256 => bytes32[]) _editionHashes;

    // edition fields
    mapping(bytes32 => Edition) private _edition;
    
    // editions state
    mapping(bytes32 => bool) private _states;

    // External Token uniqueIdentifier to tokenContract/tokenId
    mapping(uint256 => NFTDescriptor) public externalToken;

    constructor (
        string memory name_, 
        string memory symbol_
    ) ERC721(name_, symbol_) {}
    
    modifier onlyParent(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), 'Distributor: caller is not parent');
        _;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (_editionHash[tokenId] != bytes32(0)) {
            return super.ownerOf(tokenId);
        } else {
            return IERC721(externalToken[tokenId].tokenContract).ownerOf(externalToken[tokenId].tokenId);
        }
    }

    function registerOrigin(address tokenContract, uint256 tokenId, bytes calldata data) external {
        if (tokenContract == address(this)) revert ('Distributor: Invalid Token Contract');
        uint256 uniqueIdentifier = _getUniqueTokenIdentifier(tokenContract, tokenId);
        externalToken[uniqueIdentifier] = NFTDescriptor(tokenContract, tokenId);
        emit RegisterOrigin(tokenContract, tokenId, uniqueIdentifier);
    }

    function _getUniqueTokenIdentifier(
        address tokenContract,
        uint256 tokenId
    ) internal view returns(uint256 uniqueIdentifier) {
        uniqueIdentifier = uint256(keccak256(abi.encode(tokenContract, tokenId, block.chainid)));
    }

    /// @inheritdoc IDistributor
    function setEdition(
        uint256 tokenId,
        address validator,
        uint96  attibutes,
        bytes calldata initData
    ) external override onlyParent(tokenId) returns (bytes32) {

        Edition memory edition = Edition(tokenId, validator, attibutes);

        bytes32 editionHash = _getEditionHash(tokenId);
        
        _storeEdition(edition, editionHash);
        _states[editionHash] = true; // enable minting

        IValidator(edition.validator).setRules(editionHash, initData);
        
        emit SetEdition(editionHash, tokenId, validator, attibutes);
        return editionHash;
    }
    
    function _storeEdition(
        Edition memory edition,
        bytes32 editionHash
    ) internal {
        _editionHashes[edition.tokenId].push(editionHash);
        _edition[editionHash] = edition;
    }

    /// @inheritdoc IDistributor
    function pauseEdition(
        bytes32 editionHash,
        bool isPaused
    ) external override onlyParent(_edition[editionHash].tokenId) {
        _states[editionHash] = !isPaused; // disable minting
        emit PauseEdition(editionHash, isPaused);
    }
    
    // validate condition fulfilment and mint
    function mint(address to, bytes32 editionHash) external payable returns (uint256) {
        require(_states[editionHash], 'Distributor: Minting Disabled');
        IValidator(_edition[editionHash].validator).validate{value: msg.value}(to, editionHash, 0, bytes(''));
        
        uint256 tokenId = _mintToken(to);
        _tokenURI[tokenId] = _fetchURIFromParent(_edition[editionHash].tokenId);
        _editionHash[tokenId] = editionHash;
        
        return tokenId;
    }
    
    function revoke(uint256 tokenId) external onlyParent(_edition[_editionHash[tokenId]].tokenId) {
        require(isPermitted(tokenId, _REVOKE), 'Distributor: Non-revokable');
        delete _tokenURI[tokenId];
        delete _editionHash[tokenId];
        _burn(tokenId);
    }

    function destroy(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner nor approved'
        );
        delete _tokenURI[tokenId];
        delete _editionHash[tokenId];
        _burn(tokenId);
    }

    function update(uint256 tokenId) external returns (string memory) {
        require(isPermitted(tokenId, _UPDATE), 'Distributor: Non-updatable');
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner nor approved'
        );
        _tokenURI[tokenId] = _fetchURIFromParent(_edition[_editionHash[tokenId]].tokenId);
        return _tokenURI[tokenId];
    }

    function _mintToken(address to) internal returns (uint256) {
        uint256 tokenId = ++_tokenCounter;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function _fetchURIFromParent(uint256 tokenId) internal view returns (string memory) {
        return IERC721Metadata(externalToken[tokenId].tokenContract).tokenURI(externalToken[tokenId].tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (address(0) != from && address(0) != to) {
            // disable transfer if the token is not transferable. It does not apply to mint/burn action
            require(isPermitted(tokenId, _TRANSFER), 'Distributor: Non-transferable');
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _getEditionHash(
        uint256 tokenId
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    tokenId,
                    _editionHashes[tokenId].length
                )
            );
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return _tokenURI[tokenId];
    }

    function isPermitted(uint256 tokenId, uint96 action) view public returns (bool) {
        return _edition[_editionHash[tokenId]].actions & action == action;
    }
    
    function getEdition(bytes32 editionHash) external view returns (Edition memory) {
        return _edition[editionHash];
    }
    
    function getEditionHashes(uint256 tokenId) external view returns (bytes32[] memory) {
        return _editionHashes[tokenId];
    }

}
