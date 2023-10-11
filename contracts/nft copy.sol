// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./multiownable.sol";

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
}

contract NFTMarketplace is ERC721URIStorage, MultiOwnable {
    using Counters for Counters.Counter;

    address public bep20TokenAddress;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        string name;
        string tokenURI;
        // store the name of the crypto currency used to buy the NFT
        string currency;
        address currencyAddress;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold,
        string name,
        string tokenURI,
        string currency,
        address currencyAddress
    );

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 0.0000025 ether;
    address payable owner;
    mapping(uint256 => MarketItem) private idToMarketItem;

    constructor(address _bep20TokenAddress) ERC721("B2S Tokens", "B2SNFT") {
        owner = payable(msg.sender);
        bep20TokenAddress = _bep20TokenAddress;
    }

    function updateListingPrice(uint256 _listingPrice) public payable {
        require(owner == msg.sender);
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createToken(string memory tokenURI, uint256 price, string memory name, bool isBNB)
        public
        payable
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price, name, tokenURI, isBNB);
        return newTokenId;
    }

    // createTokenV2 allows only the owners of the contract to create a token
    function createTokenV2(string memory tokenURI, uint256 price, string memory name, bool isBNB) public payable onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price, name, tokenURI, isBNB);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price, string memory name, string memory tokenURI, bool isBNB) private {
        require(price > 0, "Price must be greater than 0");
        require(msg.value == listingPrice);
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false,
            name,
            tokenURI,
            isBNB ? "BNB" : "BEP20",
            isBNB ? address(0) : bep20TokenAddress
        );
        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false,
            name,
            tokenURI,
            isBNB ? "BNB" : "BEP20",
            isBNB ? address(0) : bep20TokenAddress
        );
    }

    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(idToMarketItem[tokenId].owner == msg.sender);
        require(msg.value == listingPrice);
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }

    function resellTokenV2(uint256 tokenId, uint256 price, bool isBNB) public payable {
        require(idToMarketItem[tokenId].owner == msg.sender);
        require(msg.value == listingPrice);
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        idToMarketItem[tokenId].currency = isBNB ? "BNB" : "BEP20";
        idToMarketItem[tokenId].currencyAddress = isBNB ? address(0) : bep20TokenAddress;
        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }

    // a createMarketSale function that allows users to buy a token that is already listed on the marketplace
    // this function should transfer ownership of the token to the user, as well as transfering the funds to the seller
    // the buyer should pay in the currency specified in the token listing (either BNB or BEP20)
    // the seller should be able to choose whether they want to be paid in BNB or BEP20
    function createMarketSaleV2(uint256 tokenId) public payable {
        uint256 price = idToMarketItem[tokenId].price;
        address payable seller = idToMarketItem[tokenId].seller;
        address payable buyer = payable(msg.sender);
        // require(msg.value == price);
        // if the currency is BNB, then the buyer must send the exact amount of BNB to the seller
        if (keccak256(abi.encodePacked(idToMarketItem[tokenId].currency)) == keccak256(abi.encodePacked("BNB"))) {
            require(msg.value == price, "Incorrect amount of BNB sent.");
        } else {
            // if the currency is BEP20, then the buyer must approve the contract to spend the BEP20 tokens
            // and the contract will transfer the tokens to the seller
            // the buyer should have enough BEP20 tokens to pay for the NFT
            require(IBEP20(idToMarketItem[tokenId].currencyAddress).balanceOf(buyer) >= price, "Insufficient balance.");
        }

        idToMarketItem[tokenId].owner = buyer;
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].seller = payable(address(0));
        _itemsSold.increment();
        _transfer(address(this), buyer, tokenId);
        payable(owner).transfer(listingPrice);
        if (keccak256(abi.encodePacked(idToMarketItem[tokenId].currency)) == keccak256(abi.encodePacked("BNB"))) {
            seller.transfer(msg.value);
        } else {
            IBEP20(idToMarketItem[tokenId].currencyAddress).transferFrom(buyer, seller, price);
        }
    }

    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idToMarketItem[tokenId].price;
        address payable creator = idToMarketItem[tokenId].seller;
        require(msg.value == price);
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].seller = payable(address(0));
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice);
        payable(creator).transfer(msg.value);
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            // check if nft is mine
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function burnNFT(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }
}
