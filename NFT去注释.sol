// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NicMeta is ERC721Enumerable, Ownable {
    using Strings for uint256;
    bool public _isSaleActive = false;
    bool public _revealed = true;
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxBalance = 5;
    uint256 public maxMint = 1;
    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";
    mapping(uint256 => string) private _tokenURIs;
    constructor(string memory initBaseURI, string memory initNotRevealedUri)
        ERC721("Nic Meta", "NM")
    {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }
    function mintNicMeta(uint256 tokenQuantity) public payable {
        require(
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(_isSaleActive, "Sale must be active to mint NicMetas");
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            "Sale would exceed max balance"
        );
        require(
            tokenQuantity * mintPrice <= msg.value,
            "Not enough ether sent"
        );
        require(tokenQuantity <= maxMint, "Can only mint 1 tokens at a time");
        _mintNicMeta(tokenQuantity);
    }
    function _mintNicMeta(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (_revealed == false) {
            return notRevealedUri;
        }
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }
    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }
    //set price
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }
    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }
    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }
    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}
