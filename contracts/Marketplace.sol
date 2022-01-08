// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _productIds;
    Counters.Counter private _productsSold;

    address payable owner;
    uint256 registerPrice = 0.001 ether;

    constructor(){
        owner = payable(msg.sender); //(address): sender of the message (current call)
    }
    struct MarketProduct {
        uint productId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner ;
        uint256 price ;
        bool sold;
    }
    mapping(uint256 => MarketProduct) private idToMarketProduct ; //mapping/associate key(idToMarketProduct) to value

    event MarketProductMinted(
    uint indexed productId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
    ) ;


  /* Returns the registration price of the contract */
  function getRegistrationPrice() public view returns (uint256) {
    return registerPrice;
  }
    //create/mint the new 
  function mintMarketProduct(address nftContract,  uint256 tokenId, uint256 price) public payable nonReentrant  {
 require(price > 0, "Price must be at least 1 wei");
    require(msg.value == registerPrice, "Price must be equal to listing price");
    _productIds.increment();
    uint256 productId = _productIds.current();
    idToMarketProduct[productId] =  MarketProduct(
      productId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      false );

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit MarketProductMinted(
      productId,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price,
      false
    );
  } 

  /* Returns all unsold market product*/
  function fetchMarketProducts() public view returns (MarketProduct[] memory) {
    uint productCount = _productIds.current();
    uint unsoldProductCount = _productIds.current() - _productsSold.current();
    uint currentIndex = 0;

    MarketProduct[] memory products = new MarketProduct[](unsoldProductCount);
    for (uint i = 0; i < productCount; i++) {
      if (idToMarketProduct[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketProduct storage currentProduct = idToMarketProduct[currentId];
        products[currentIndex] = currentProduct;
        currentIndex += 1;
      }
    }
    return products;
  }

 /* Returns only products a user has created */
  function fetchProductsCreated() public view returns (MarketProduct[] memory) {
    uint totalProductCount = _productIds.current();
    uint productCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalProductCount; i++) {
      if (idToMarketProduct[i + 1].seller == msg.sender) {
        productCount += 1;
      }
    }

    MarketProduct[] memory products = new MarketProduct[](productCount);
    for (uint i = 0; i < totalProductCount; i++) {
      if (idToMarketProduct[i + 1].seller == msg.sender) {
        uint currentId = i + 1;
        MarketProduct storage currentProduct = idToMarketProduct[currentId];
        products[currentIndex] = currentProduct;
        currentIndex += 1;
      }
    }
    return products;
  }


}
