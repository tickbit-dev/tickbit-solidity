// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Tickbit.sol";

contract TickbitTicket is Ownable, ERC721 {
    // ----------------------- INSTANCES  -----------------------
    AggregatorV3Interface internal chainlinkMaticUSD;
    Tickbit tickbitContract;
    
    // ----------------------- COUNTERS  -----------------------
    using Counters for Counters.Counter;
    Counters.Counter private _ticketsIds;
    Counters.Counter private _resalesIds;

    // ----------------------- MAPPINGS  -----------------------
    //Ticketing
    mapping(uint256 => TicketItem) private idToTicket;
    mapping(uint256 => uint256[]) private idEventToIdTicketArray;
    mapping(uint256 => TicketValidation) private idTicketToTicketValidation;
    mapping(uint256 => TicketResale) private idToTicketResale;

    // ----------------------- STRUCTS -----------------------

    //Ticket data
    struct TicketItem {
        address _owner;
        address _eventOwner;
        uint256 _id;
        uint256 _purchaseDate;
        uint256 idEvent;
        uint256 price;
        bool validated;
        bool isOnSale;
    }

    //Ticket data
    struct TicketValidation {
        uint256 _validationDate;
        uint256 idTicket;
        uint256 idEvent;
        uint256 validationHash;
    }

    //Ticket data
    struct TicketResale {
        uint256 _id;
        uint256 _resaleDate;
        uint256 idTicket;
        uint256 idEvent;
        bool isSold;
        bool isCancelled;
    }

    // ----------------------- EVENTS -----------------------

    event TicketItemCreated(
        address indexed _owner,
        address indexed _eventOwner,
        uint256 indexed _id,
        uint256 _purchaseDate,
        uint256 idEvent
    );

    event TicketItemValidation(
        uint256 _validationDate,
        uint256 idTicket,
        uint256 idEvent,
        uint256 validationHash
    );

    event TicketItemValidated(
        bool validated
    );

    constructor() ERC721("Tickbit Tickets", "TCKB") {
        chainlinkMaticUSD = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        tickbitContract = Tickbit(0xEa24F063385487F264b7E17c57cf3512fc5191a1);
    }

    /**
     * $dev The user pay for tickets and get the ticket token generated
     * $param idEvent Id of the event
     * $param noOfTickets Number of tickets to buy
     *
     **/
    function buyTicket(uint256 idEvent, uint256 noOfTickets) public payable {
        //Checks if the noOfTickets is a valid number
        require(noOfTickets <= 5, "You can't buy more than 5 tickets in one order");

        Tickbit.EventItem memory eventItem = tickbitContract.readEvent(idEvent, true);
        
        //The price needs to be equal to the amount the sender address sends.
        require(msg.value <= ((getMaticWeiFromUSD(eventItem.price) * noOfTickets) + getMaticWeiFromUSD(1)), "Wrong amount sent");
        require(msg.value >= ((getMaticWeiFromUSD(eventItem.price) * noOfTickets) - getMaticWeiFromUSD(1)), "Wrong amount sent");

        //Checks if the event has availability
        require(eventItem.capacity >= (idEventToIdTicketArray[eventItem._id].length + noOfTickets), "No availability for this event");

        //Transfers the money to the event owner address
        uint256 sellerPercent = (msg.value * 95) / 100;
        payable(eventItem._owner).transfer(sellerPercent);

        //Transfers the fee to the contract owner address
        payable(owner()).transfer(msg.value - sellerPercent);

        for(uint256 i = 0; i < noOfTickets; i++) {
            //increments _ticketsIds global counter
            _ticketsIds.increment();
            uint256 ticketId = _ticketsIds.current();

            idToTicket[ticketId] = TicketItem(
                msg.sender,
                eventItem._owner,
                ticketId,
                block.timestamp,
                idEvent,
                eventItem.price,
                false,
                false
            );

            _mint(msg.sender, ticketId);

            //Adds the ticketId in the idEventToIdTicketArray mapping at idEventt positon
            idEventToIdTicketArray[idEvent].push(ticketId);

            emit TicketItemCreated(msg.sender, eventItem._owner, ticketId, block.timestamp, idEvent);
        }
    }

    /**
     * $dev The user pay for tickets on resale and traspass the ticket token
     * $param idEvent Id of the event
     * $param noOfTickets Number of tickets to buy
     *
     **/
    function buyResaleTicket(uint256 idEvent, uint256 noOfTickets) public payable {
        //Checks if the noOfTickets is a valid number
        require(noOfTickets <= 5, "You can't buy more than 5 tickets in one order");

        Tickbit.EventItem memory eventItem = tickbitContract.readEvent(idEvent, true);
        uint256[] memory resaleIdItems = getResalesForEvent(idEvent);

        //The price needs to be equal to the amount the sender address sends.
        require(msg.value <= ((getMaticWeiFromUSD(eventItem.price) * noOfTickets) + getMaticWeiFromUSD(1)), "Wrong amount sent");
        require(msg.value >= ((getMaticWeiFromUSD(eventItem.price) * noOfTickets) - getMaticWeiFromUSD(1)), "Wrong amount sent");

        //Checks if the event has no availability
        require(eventItem.capacity == idEventToIdTicketArray[eventItem._id].length, "Event already available");

        //Checks if the event has resell availability
        require(resaleIdItems.length >= noOfTickets, "No availability for this event");

        for(uint256 i = 0; i < noOfTickets; i++) {
            //Último ticket
            uint256 resaleIdItem = resaleIdItems[i];
            TicketItem memory ticketItem = idToTicket[idToTicketResale[resaleIdItem].idTicket];

            //Transfers the money to the event owner address
            uint256 sellerPercent = ((msg.value / noOfTickets) * 90) / 100;
            payable(ticketItem._owner).transfer(sellerPercent);

            //Transfers 9% fee to the event owner address
            uint256 eventOwnerPercent = ((msg.value / noOfTickets) * 9) / 100;
            payable(eventItem._owner).transfer(eventOwnerPercent);

            //Transfers the 1% fee to the tickbit owner address
            payable(owner()).transfer((msg.value / noOfTickets) - sellerPercent - eventOwnerPercent);

            //Transfers the ticket token to the new owner
            _transfer(ticketItem._owner, msg.sender, ticketItem._id);

            //Change the parameters
            idToTicket[idToTicketResale[resaleIdItem].idTicket]._owner = msg.sender;
            idToTicket[idToTicketResale[resaleIdItem].idTicket].isOnSale = false;
            idToTicketResale[resaleIdItem].isSold = true;
        }
    }

    /**
     * $dev Returns the resales for a idEvent
     * $param idEvent Id of the event
     *
     **/
    function getResalesForEvent(uint256 idEvent) public view returns (uint256[] memory) {
        uint256 myResalesCount = 0;

        for(uint256 i = 0; i < _resalesIds.current(); i++) {
            if(idToTicketResale[i + 1].isSold == false && idToTicketResale[i + 1].idEvent == idEvent && idToTicketResale[i + 1].isCancelled == false){
                myResalesCount += 1;
            }
        }

        uint256[] memory idResalesItems = new uint256[](myResalesCount);
        uint256 currentCount = 0;

        for(uint256 i = 0; i < _resalesIds.current(); i++) {
            if(idToTicketResale[i + 1].isSold == false && idToTicketResale[i + 1].idEvent == idEvent && idToTicketResale[i + 1].isCancelled == false){
                idResalesItems[currentCount] = idToTicketResale[i + 1]._id;
                currentCount += 1;
            }
        }

        return idResalesItems;
    }

    /**
     * $dev Returns the incomes for resales tickets
     *
     **/
    function getResalesIncomes() public view returns (TicketResale[] memory) {
        uint256 myResalesCount = 0;

        for(uint256 i = 0; i < _resalesIds.current(); i++) {
            Tickbit.EventItem memory eventItem = tickbitContract.readEvent(idToTicketResale[i + 1].idEvent, true);

            if(idToTicketResale[i + 1].isSold == true && (msg.sender == owner() || eventItem._owner == msg.sender)){
                myResalesCount += 1;
            }
        }

        TicketResale[] memory resalesItems = new TicketResale[](myResalesCount);
        uint256 currentCount = 0;

        for(uint256 i = 0; i < _resalesIds.current(); i++) {
            Tickbit.EventItem memory eventItem = tickbitContract.readEvent(idToTicketResale[i + 1].idEvent, true);

            if(idToTicketResale[i + 1].isSold == true && (msg.sender == owner() || eventItem._owner == msg.sender)){
                resalesItems[currentCount] = idToTicketResale[i + 1];
                currentCount += 1;
            }
        }

        return resalesItems;
    }

    /**
     * $dev Cheks the availability from resales tickets for a event
     * $param idEvent Id of the event
     *
     **/
    function checkResaleAvailability(uint256 idEvent) public view returns (uint) {
        return getResalesForEvent(idEvent).length;
    }

    /**
     * $dev Resales a ticket
     * $param idTicket Id of the ticket
     *
     **/
    function resaleTicket(uint256 idTicket) public {
        //Checks the ownership of the ticket
        require(idToTicket[idTicket]._owner == msg.sender, "You are not the ticket owner");

        //Checks if the ticket is already validated
        require(idToTicket[idTicket].validated == false, "Ticket already validated");

        //Checks if the ticket is already validated
        require(idToTicket[idTicket].isOnSale == false, "Ticket already on sale");

        //Increments _resalesIds global counter
        _resalesIds.increment();
        uint256 resaleId = _resalesIds.current();

        //Creates a new resale and saves it in idToResale mapping
        idToTicketResale[resaleId] = TicketResale(
            resaleId,
            block.timestamp,
            idTicket,
            idToTicket[idTicket].idEvent,
            false,
            false
        );

        //Change parameters
        idToTicket[idTicket].isOnSale = true;
    }

    /**
     * $dev Cancels the ticket resale
     * $param idTicket Id of the ticket
     *
     **/
    function cancelResale(uint256 idTicket) public {
        //Checks the ownership of the ticket
        require(idToTicket[idTicket]._owner == msg.sender, "You are not the ticket owner");

        //Checks if the ticket is already validated
        require(idToTicket[idTicket].validated == false, "Ticket already validated");

        //Checks if the ticket is already validated
        require(idToTicket[idTicket].isOnSale == true, "Ticket is not on sale");

        uint256 idResale = 0;

        for(uint256 i = 0; i < _resalesIds.current(); i++) {
            if(idToTicketResale[i + 1].isSold == false && idToTicketResale[i + 1].idTicket == idTicket && idToTicketResale[i + 1].isCancelled == false){
                idResale = i + 1;
            }
        }

        require(idResale != 0, "Invalid ticket");

        //Change parameters
        idToTicket[idTicket].isOnSale = false;
        idToTicketResale[idResale].isCancelled = true;
    }

    /**
     * $dev Checks the availability for a event
     * $param idEvent Id of the event
     *
     **/
    function checkAvailavilityFromIdEvent(uint256 idEvent) public view returns (uint) {
        Tickbit.EventItem memory eventItem = tickbitContract.readEvent(idEvent, true);

        return eventItem.capacity - idEventToIdTicketArray[eventItem._id].length;
    }

    /**
     * $dev Returns the ticketing sales
     *
     **/
    function readTicketingSales() public view returns (TicketItem[] memory) {
        uint256 ticketCount = _ticketsIds.current();
        uint256 myTicketCount = 0;
        uint256 currentIndex = 0;

        //Contract owner gets a counter of all the existing tickets
        //User gets a counter of all the tickets created by him
        for (uint256 i = 0; i < ticketCount; i++) {
            if(idToTicket[i + 1]._eventOwner == msg.sender || msg.sender == owner()) {
                myTicketCount += 1;
            }
        }

        TicketItem[] memory tickets = new TicketItem[](myTicketCount);

        //Contract owner gets an array with all the tickets
        //User gets an array with the tickets purchased by him
        for (uint256 i = 0; i < ticketCount; i++) {
            //Checks the owner of the ticket
            if (idToTicket[i + 1]._eventOwner == msg.sender || msg.sender == owner()) {
                //Add ticket to the array
                uint256 currentId = i + 1;
                TicketItem storage currentTicket = idToTicket[currentId];
                tickets[currentIndex] = currentTicket;
                currentIndex += 1;
            }
        }

        return tickets;
    }

    /**
     * $dev Reads all tickets from clients
     * $return TicketItem[] TicketItem structs array with all the tickets
     */
    function readTickets() public view returns (TicketItem[] memory) {
        uint256 ticketCount = _ticketsIds.current();
        uint256 myTicketCount = 0;
        uint256 currentIndex = 0;

        //Contract owner gets a counter of all the existing tickets
        //User gets a counter of all the tickets created by him
        for (uint256 i = 0; i < ticketCount; i++) {
            if (idToTicket[i + 1]._owner == msg.sender ) {
                myTicketCount += 1;
            }
        }

        TicketItem[] memory tickets = new TicketItem[](myTicketCount);

        //Contract owner gets an array with all the tickets
        //User gets an array with the tickets purchased by him
        for (uint256 i = 0; i < ticketCount; i++) {
            //Checks the owner of the ticket
            if (idToTicket[i + 1]._owner == msg.sender) {
                //Add ticket to the array
                uint256 currentId = i + 1;
                TicketItem storage currentTicket = idToTicket[currentId];
                tickets[currentIndex] = currentTicket;
                currentIndex += 1;
            }
        }

        return tickets;
    }

    /**
     * $dev Consults the number tickets sold for a specific event
     * $return uint256 Number of tickets sold for the specifies event
     */
    function ticketsSoldByIdEvent(uint256 idEvent) public view returns (uint256) {
        uint256[] memory idTickets = idEventToIdTicketArray[idEvent];

        return idTickets.length;
    }

    function getMaticUsd() public view returns (int) {(,int price,,,) = chainlinkMaticUSD.latestRoundData();
        return price * 1e10;
    }

    function getMaticWeiFromUSD(uint _amuontinUsd) public view returns (uint){
        uint newInput = _amuontinUsd * 10 ** 18; 
        uint MaticUsd = uint(getMaticUsd());

        return (newInput * 10 ** 18) / MaticUsd;
    }

    function validateTicket(uint256 idTicket, uint256 validationHash, uint256 idEvent) public {
        TicketItem memory ticketItem = idToTicket[idTicket];

        require(ticketItem.idEvent == idEvent, "This ticket does not correspond to this event");
        require(ticketItem._owner == msg.sender, "Invalid owner");
        require(ticketItem.validated == false, "Ticket already validated");
        require(ticketItem.isOnSale == false, "Ticket on sale");

        //Tickbit.EventItem memory eventItem = tickbitContract.readEvent(ticketItem.idEvent, true);

        idTicketToTicketValidation[ticketItem._id] = TicketValidation(
            block.timestamp,
            idTicket,
            ticketItem.idEvent,
            validationHash
        );

        //_transfer(msg.sender, eventItem._owner, idTicket);

        emit TicketItemValidation(block.timestamp, idTicket, ticketItem.idEvent, validationHash);
    }

    function checkTicketValidation(uint256 idEvent, uint256 validationHash) public {
        Tickbit.EventItem memory eventItem = tickbitContract.readEvent(idEvent, true);

        require(eventItem._owner == msg.sender, "Invalid event owner");

        uint256[] memory tickets = idEventToIdTicketArray[idEvent];

        TicketItem memory currentTicket;
        uint256 currentHash = 0;
        bool valid = false;

        for(uint256 i = 0; i < tickets.length; i++) {
            currentTicket = idToTicket[tickets[i]];
            currentHash = idTicketToTicketValidation[currentTicket._id].validationHash;

            if(currentTicket.validated != true){
                if(currentHash == validationHash && currentTicket.isOnSale == false){
                    idToTicket[currentTicket._id].validated = true;
                    valid = true;
                }
            }
        }

        require(valid == true, "Validation not valid");
    }

    function checkTicketValidationTest(uint256 idEvent, uint256 validationHash) public view {
        Tickbit.EventItem memory eventItem = tickbitContract.readEvent(idEvent, true);

        require(eventItem._owner == msg.sender, "Invalid event owner");

        uint256[] memory tickets = idEventToIdTicketArray[idEvent];

        TicketItem memory currentTicket;
        uint256 currentHash = 0;
        bool valid = false;

        for(uint256 i = 0; i < tickets.length; i++) {
            currentTicket = idToTicket[tickets[i]];
            currentHash = idTicketToTicketValidation[currentTicket._id].validationHash;

            if(currentTicket.validated != true){
                if(currentHash == validationHash && currentTicket.isOnSale == false){
                    valid = true;
                }
            }
        }

        require(valid == true, "Validation not valid");
    }
}