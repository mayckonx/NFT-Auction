// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/**
 * @title Repository of ERC721 Deeds
 * This contract contains the list of deeds registered by users.
 */
contract DeedRepository is ERC721URIStorage {
    event DeedRegistered(address _by, uint256 _tokenId);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function registerDeed(uint256 _tokenId, string memory _uri) public {
        _mint(msg.sender, _tokenId);
        bool result = addDeedMetadata(_tokenId, _uri);
        if (result) {
            emit DeedRegistered(msg.sender, _tokenId);
        } else {
            revert();
        }
    }

    function addDeedMetadata(uint256 _tokenId, string memory _uri)
        public
        returns (bool)
    {
        _setTokenURI(_tokenId, _uri);
        return true;
    }

    /**
     * @dev Disallow payments to this contract directly
     */
    receive() external payable {
        revert();
    }
}
