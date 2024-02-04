// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract TicketNFT is ERC1155, ITicketNFT {
    // your code goes here (you can do it!)

    address public owner;

    constructor() ERC1155("https://ipfs.io/ipfs/") {
        owner = msg.sender;
    }

    function mintFromMarketPlace(address to, uint256 nftId) external {
        require(msg.sender == owner, "Only owner can mint NFTs");
        // console.log("Minting NFT with id %s to address %s", nftId, to);
        // console.log((nftId>>128), nftId&((1<<128) - 1));
        _mint(to, nftId, 1, "");
    }
}