// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NicMeta is ERC721Enumerable, Ownable {
    using Strings for uint256;
    //是否开始公售
    bool public _isSaleActive = false;
    //是否开启盲盒
    bool public _revealed = false;

    // Constants
    //最大供应量
    uint256 public constant MAX_SUPPLY = 10;
    //公售价格
    uint256 public mintPrice = 0.3 ether;
    //钱包最大持有
    uint256 public maxBalance = 1;
    //一次MINT最大数量
    uint256 public maxMint = 1;
    //NFT的JSON图片的ipfs
    string baseURI;
    //盲盒的ipfs
    string public notRevealedUri;
    //nft格式
    string public baseExtension = ".json";
    //存储已经MINT的NFT的ipfs地址
    mapping(uint256 => string) private _tokenURIs;
    //构造函数  ERC721('NFT名字','NFT简写')
    constructor(string memory initBaseURI, string memory initNotRevealedUri)
        ERC721("Nic Meta", "NM")
    {
        //设置json路径
        setBaseURI(initBaseURI);
        //设置盲盒路径
        setNotRevealedURI(initNotRevealedUri);
    }
    //铸造  传递mint的数量
    function mintNicMeta(uint256 tokenQuantity) public payable {
        //判断当前已经mint的加上本次mint的数量会不会超过最大供应量，超过则失败
        require(
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        //判断是否开始公售，不是则失败
        require(_isSaleActive, "Sale must be active to mint NicMetas");
        //判断当前用户所持有的加上本次mint的数量会不会超过每个钱包限制的数量，超过则失败
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            "Sale would exceed max balance"
        );
        //判断当前用户是否持有本次mint的金额，余额不足则失败
        require(
            tokenQuantity * mintPrice <= msg.value,
            "Not enough ether sent"
        );
        //判断本次mint数量会不会超过单次限制的最大mint数量，超过则失败
        require(tokenQuantity <= maxMint, "Can only mint 1 tokens at a time");
        //开始mint
        _mintNicMeta(tokenQuantity);
    }
    //真正的mint方法
    function _mintNicMeta(uint256 tokenQuantity) internal {
        //循环mint
        for (uint256 i = 0; i < tokenQuantity; i++) {
            //获取当前已经mint的数量，将本次mint的tokenId设置为当前的数量
            uint256 mintIndex = totalSupply();
            //如果当前的存储nft数量不大于总供应量，则进行mint
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    //获取当前的totalSupply
    function getTotal()returns(uint256 totalSupply){
        return totalSupply();
    }
    //查询nft的ipfs数据
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        //判断当前tokenId是否存在，不存在则失败
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        //如果盲盒还没有开启，则返回盲盒的数据
        if (_revealed == false) {
            return notRevealedUri;
        }
        //返回ipfs数据
        string memory _tokenURI = _tokenURIs[tokenId];
        //拿到nft的json的ipfs
        string memory base = _baseURI();

        // 如果说nft的json的ipfs不存在，则直接返回单个当前nft的url
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // 如果说当前nft的url大于0.则返回拼接baseurl和当前nft的url后的地址
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // 不然就返回base的url+当前token的id+设置的后缀(.json)
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    //查看当前的baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //开启或者关闭公售
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }
    //开启或者关闭盲盒
    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }
    //设置mint的价格
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
    //设置盲盒的URI
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    //设置baseURI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    //nftURI返回的后缀格式(.json)
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }
    //设置钱包的最大持有量
    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }
    //设置单次最大的mint数量
    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }
    //提现
    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}
