// SPDX-License-Identifier: MIT

import "./EutLibrary.sol";
import "./ERC721.sol";

// EutMusic is authored by Eut.io
// Holds who owns what
// Contract.balance Holds CO's profit.

pragma solidity >=0.6.0 <0.8.0;
/**
 * @title EutMusic contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract EutMusic is ERC721, Ownable {
    using SafeMath for uint256;

    string public constant musicTokenSymbol = "EUT";

    uint256 public constant musicPrice = 80000000000000000; //0.08 ETH

    uint public constant maxMusicPurchase = 20;

    uint256 public MAX_MUSIC = 150;

    bool public saleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;

    uint public constant lockPeriodInSec = 86400 * 9; // Reveal after 9 days

    // prices
    // tokenId : expectedPriceToBeSold
    mapping (uint256 => uint) public _tokenPrices;

    // Events
    event mintedEvent (
        uint indexed _tokenId
    );

    constructor(string memory _name, uint256 saleStart) ERC721(_name, musicTokenSymbol) {
        REVEAL_TIMESTAMP = saleStart + lockPeriodInSec;

        //Self minting for demo
        //Remove in prod
        flipSaleState();
        mintMusicOne();
        mintMusicOne();
        mintMusicOne();
        _setTokenURI(0,"url://music1");
        _setTokenURI(1,"url://music2");
        _setTokenURI(2,"url://music3");
        setPriceByCO(0,3);
        setPriceByCO(1,3);
        setPriceByCO(2,3);
    }

    // withdraw removes an NFT from the collection and moves it to the caller
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     * Discord that you're standing right behind him.
     */
    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }


    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
    * Mints Music, By CO(contract owner)
    */
    function mintMusicMultiple(uint numberOfTokens) public onlyOwner payable {
        require(saleIsActive, "Sale must be active to mint Music");
        require(numberOfTokens <= maxMusicPurchase, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_MUSIC, "Purchase would exceed max supply of Music");
        require(musicPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply(); // Current watermark
            if (totalSupply() < MAX_MUSIC) {
                uint256 tokenId = mintIndex;
                _safeMint(msg.sender, tokenId);
                _tokenPrices[tokenId] = 0; // Not for sale until otherwise
            }
        }
    }

    function mintMusicOne() public onlyOwner {
        require(saleIsActive, "Sale must be active to mint Music");
        require(totalSupply().add(1) <= MAX_MUSIC, "Purchase would exceed max supply of Music");
        uint tokenId = totalSupply(); // Current watermark
        _safeMint(msg.sender, tokenId);
        _tokenPrices[tokenId] = 0; // Not for sale until otherwise
        emit mintedEvent(tokenId);
    }

    // EUT SPECIFIC Functions
    function getEutMusicUrl(uint256 tokenId) public view returns (string memory)  {
        return tokenURI(tokenId);
    }

    function getOwnerByTokenId(uint256 tokenId) public view returns (address) {
        return ownerOf(tokenId);
    }

    // EUT SPECIFIC Transaction Functions
    /**
    * CO can assign music to any specific owner
    * can only set for freshly minted musics
    */
    function airDropInitialOwner(address _to, uint256 tokenId) public onlyOwner {
        require(saleIsActive, "Sale must be active");
        require(_exists(tokenId), "EutMusic: nonexistent token");
        require(msg.sender==getOwnerByTokenId(tokenId), "EutMusic: CO does not own this token");
        _transfer(msg.sender, _to, tokenId);
    }

    // CO overrides owner
    function setPriceByCO(uint256 tokenId, uint price) public onlyOwner {
        require(saleIsActive, "Sale must be active");
        require(_exists(tokenId), "EutMusic: nonexistent token");
        _tokenPrices[tokenId] = price;
    }

    function setPriceByOwner(uint256 tokenId, uint price) public {
        require(saleIsActive, "Sale must be active");
        require(_exists(tokenId), "EutMusic: nonexistent token");
        require(msg.sender==getOwnerByTokenId(tokenId), "EutMusic: sender does not own this token");
        _tokenPrices[tokenId] = price;
    }

    function reserveMusicByOwner(uint256 tokenId) public{
        require(saleIsActive, "Sale must be active");
        require(_exists(tokenId), "EutMusic: nonexistent token");
        require(msg.sender==getOwnerByTokenId(tokenId), "EutMusic: sender does not own this token");
        setPriceByOwner(tokenId, 0);
    }

    // An order is executed if price is satisfied.
    function buyAsSatisfyingPrice(uint256 tokenId) public payable{
        require(saleIsActive, "Sale must be active");
        address buyer=msg.sender;
        address seller=getOwnerByTokenId(tokenId);
        require(_exists(tokenId), "EutMusic: nonexistent token");
        require(_tokenPrices[tokenId]!=0, "token is not for sale"); //token is for sale
        require(msg.value >= _tokenPrices[tokenId], "price is not satisfied");

        _transfer(seller, buyer, tokenId); //ERC721 does not confirm msg.sender has to be seller.
        payable(seller).transfer(msg.value);
        _tokenPrices[tokenId]=0;
    }

}