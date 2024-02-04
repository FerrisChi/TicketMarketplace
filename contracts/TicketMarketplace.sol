// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    // your code goes here (you can do it!)

    address public owner;
    address public nftContract;
    address public ERC20Address;
    uint128 public currentEventId;
    
    struct Event {
        uint128 eventId;
        uint128 nextTicketToSell;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }
    mapping(uint128 => Event) public events;
    // Event[] public events;
    
    constructor(address _ERC20Address) {
        // setERC20Address(_ERC20Address);
        ERC20Address = _ERC20Address;
        TicketNFT ticketNFT = new TicketNFT();
        nftContract = address(ticketNFT);
        currentEventId = 0;
        owner = msg.sender;
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external {
        require(msg.sender == owner, "Unauthorized access");

        uint128 eventId = currentEventId++;
        events[eventId] = Event(eventId, 0, maxTickets, pricePerTicket, pricePerTicketERC20);
        emit EventCreated(eventId, maxTickets, pricePerTicket, pricePerTicketERC20);
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external {
        require(msg.sender == owner, "Unauthorized access");
        require(newMaxTickets > events[eventId].maxTickets, "The new number of max tickets is too small!");

        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external {
        require(msg.sender == owner, "Unauthorized access");

        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external {
        require(msg.sender == owner, "Unauthorized access");

        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external {
        // require(eventId < currentEventId, "Event does not exist");
        bool a;
        uint256 b;
        (a,b) = Math.tryMul(ticketCount, events[eventId].pricePerTicket);
        require(a==true, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        // require(events[eventId].pricePerTicket * ticketCount / events[eventId].pricePerTicket == ticketCount, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(msg.value >= events[eventId].pricePerTicket * ticketCount, "Not enough funds supplied to buy the specified number of tickets.");
        require(events[eventId].nextTicketToSell + ticketCount <= events[eventId].maxTickets, "We don't have that many tickets left to sell!");

        // uint256 t=events[eventId].pricePerTicket;
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 nowId = (uint256(eventId) << 128) | (events[eventId].nextTicketToSell + i);
            ITicketNFT(nftContract).mintFromMarketPlace(msg.sender, nowId);
        }
        events[eventId].nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ETH");
        // payable(msg.sender).transfer(remain);
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external {
        // require(eventId < currentEventId, "Event does not exist");
        IERC20 sampleCoin = IERC20(ERC20Address);
        bool a;
        uint256 b;
        (a,b) = Math.tryMul(ticketCount, events[eventId].pricePerTicketERC20);
        require(a==true, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        
        uint256 totalPrice = events[eventId].pricePerTicketERC20 * ticketCount;
        // require(sampleCoin.allowance(msg.sender, address(this)) >= events[eventId].pricePerTicketERC20 * ticketCount, "Not enough allowance to buy the specified number of tickets.");
        require(sampleCoin.balanceOf(msg.sender) >= totalPrice, "Not enough funds to buy the specified number of tickets.");
        require(events[eventId].nextTicketToSell + ticketCount <= events[eventId].maxTickets, "We don't have that many tickets left to sell!");

        sampleCoin.transferFrom(msg.sender, address(this), totalPrice);
        for (uint128 i = 0; i < ticketCount; i++) {
            ITicketNFT(nftContract).mintFromMarketPlace(msg.sender, (uint256(eventId) << 128) | (events[eventId].nextTicketToSell + i));
        }
        events[eventId].nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    function setERC20Address(address newERC20Address) external {
        require(msg.sender == owner, "Unauthorized access");

        ERC20Address = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }

    function getAddress() external view returns (address) {
        return address(this);
    }

}