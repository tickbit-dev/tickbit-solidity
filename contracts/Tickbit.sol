// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tickbit is Ownable {
    // ----------------------- COUNTERS  -----------------------

    using Counters for Counters.Counter;
    Counters.Counter private _eventsIds;
    Counters.Counter private _campaignsIds;

    // ----------------------- MAPPINGS  -----------------------

    //Events
    mapping(uint256 => EventItem) private idToEvent;

    //Campaign
    mapping(uint256 => CampaignItem) private idToCampaign;
    mapping(address => uint256[]) private addressToIdCampaignArray;
    mapping(uint256 => uint256[]) private initialDateToIdCampaignArray;

    // ----------------------- STRUCTS -----------------------

    //Event data
    struct EventItem {
        address _owner;
        uint256 _id;
        uint256 _insertionDate;
        string title;
        uint256 idCity;
        uint256 idVenue;
        uint256 idCategory;
        string description;
        string artist;
        uint256 capacity;
        uint256 price;
        string coverImageUrl;
        uint256 initialSaleDate;
        uint256 initialDate;
        uint256 finalDate;
        bool aproved;
        bool deleted;
    }

    //Data to create an event
    struct CreateEventInfo {
        address _owner;
        string title;
        uint256 idCity;
        uint256 idVenue;
        uint256 idCategory;
        string description;
        string artist;
        uint256 capacity;
        uint256 price;
        string coverImageUrl;
        uint256 initialSaleDate;
        uint256 initialDate;
        uint256 finalDate;
    }

    //Modified event data
    struct ModifyEventInfo {
        uint256 _id;
        string title;
        uint256 idCity;
        uint256 idVenue;
        uint256 idCategory;
        string description;
        string artist;
        uint256 capacity;
        uint256 price;
        string coverImageUrl;
        uint256 initialSaleDate;
        uint256 initialDate;
        uint256 finalDate;
    }

    //Campaign data
    struct CampaignItem {
        address _owner;
        uint256 _id;
        uint256 idType;
        uint256 eventId;
        uint256 initialDate;
        uint256 finalDate;
        uint256 price;
        uint256 purchaseDate;
    }

    // ----------------------- EVENTS -----------------------

    event EventItemCreated(
        address indexed _owner,
        uint256 indexed _id,
        uint256 _insertionDate
    );

    event EventItemModified(
        address indexed _owner,
        uint256 indexed _id,
        uint256 _insertionDate
    );

    event EventItemDeleted(
        address indexed _owner,
        uint256 indexed _id,
        uint256 _insertionDate
    );

    event EventItemRestored(
        address indexed _owner,
        uint256 indexed _id,
        uint256 _insertionDate
    );

    event CampaignItemCreated(
        address indexed _owner,
        uint256 indexed _id,
        uint256 idType,
        uint256 eventId,
        uint256 initialDate,
        uint256 finalDate,
        uint256 _purchaseDate
    );

    // ----------------------- EVENTS FUNCTIONS -----------------------

    /**
     * $dev Creates and registers a new event
     * $param _owner Owner of the event (NULL by default)
     * $param title Title of the event
     * $param idCity City of the event
     * $param idVenue Venue of the event
     * $param idCategory Category of the event
     * $param description Description of the event
     * $param artist Name of the artist of the event
     * $param capacity Number of tickets available for the event
     * $param price Price of the ticket
     * $param coverImageUrl Url of the cover image of the event
     * $param initialSaleDate Date when the event will be available to sell
     * $param initialDate Date when the event will start
     * $param finalDate Date when the event will end
     **/
    function createEvent(CreateEventInfo memory eventInfo) public {
        //increments _eventsIds global counter
        _eventsIds.increment();
        uint256 eventId = _eventsIds.current();

        //Creates a new event and saves it in idToEvent mapping at the eventId position
        idToEvent[eventId] = EventItem(
            msg.sender,
            eventId,
            block.timestamp,
            eventInfo.title,
            eventInfo.idCity,
            eventInfo.idVenue,
            eventInfo.idCategory,
            eventInfo.description,
            eventInfo.artist,
            eventInfo.capacity,
            eventInfo.price,
            eventInfo.coverImageUrl,
            eventInfo.initialSaleDate,
            eventInfo.initialDate,
            eventInfo.finalDate,
            false,
            false
        );

        emit EventItemCreated(msg.sender, eventId, block.timestamp);
    }

    /**
     * $dev Creates and registers test events
     * $param _owner Owner of the event
     * $param title Title of the event
     * $param idCity City of the event
     * $param idVenue Venue of the event
     * $param idCategory Category of the event
     * $param description Description of the event
     * $param artist Name of the artist of the event
     * $param capacity Number of tickets available for the event
     * $param price Price of the ticket
     * $param coverImageUrl Url of the cover image of the event
     * $param initialSaleDate Date when the event will be available to sell
     * $param initialDate Date when the event will start
     * $param finalDate Date when the event will end
     **/
    function createEventsTest(CreateEventInfo[] memory eventInfo) public {
        uint256 eventsCount = eventInfo.length;

        //Contract owner gets a counter of all the existing tickets
        //User gets a counter of all the tickets created by him
        for (uint256 i = 0; i < eventsCount; i++) {
            //increments _eventsIds global counter
            _eventsIds.increment();
            uint256 eventId = _eventsIds.current();

            //Creates a new event and saves it in idToEvent mapping at the eventId position
            idToEvent[eventId] = EventItem(
                eventInfo[i]._owner,
                eventId,
                block.timestamp,
                eventInfo[i].title,
                eventInfo[i].idCity,
                eventInfo[i].idVenue,
                eventInfo[i].idCategory,
                eventInfo[i].description,
                eventInfo[i].artist,
                eventInfo[i].capacity,
                eventInfo[i].price,
                eventInfo[i].coverImageUrl,
                eventInfo[i].initialSaleDate,
                eventInfo[i].initialDate,
                eventInfo[i].finalDate,
                false,
                false
            );

            emit EventItemCreated(msg.sender, eventId, block.timestamp);
        }
    }

    /**
     * $dev Edits an event
     * $param title Title of the event
     * $param idCity City of the event
     * $param idVenue Venue of the event
     * $param idCategory Category of the event
     * $param description Description of the event
     * $param artist Name of the artist of the event
     * $param capacity Number of tickets available for the event
     * $param price Price of the ticket
     * $param coverImageUrl Url of the cover image of the event
     * $param initialSaleDate Date when the event will be available to sell
     * $param initialDate Date when the event will start
     * $param finalDate Date when the event will end
     **/
    function editEvent(ModifyEventInfo memory eventInfo) public {
        uint256 id = eventInfo._id;

        //Needs to exist an event created with that id
        require(idToEvent[id]._id != 0, "This event does not exist");

        //The sender needs to be the creator of the event or be the contract owner
        require(
            idToEvent[id]._owner == msg.sender || msg.sender == owner(),
            "Invalid owner"
        );

        //Modifies the actual data with the new data
        idToEvent[id].title = eventInfo.title;
        idToEvent[id].idCity = eventInfo.idCity;
        idToEvent[id].idVenue = eventInfo.idVenue;
        idToEvent[id].idCategory = eventInfo.idCategory;
        idToEvent[id].description = eventInfo.description;
        idToEvent[id].artist = eventInfo.artist;
        idToEvent[id].capacity = eventInfo.capacity;
        idToEvent[id].price = eventInfo.price;
        idToEvent[id].coverImageUrl = eventInfo.coverImageUrl;
        idToEvent[id].initialSaleDate = eventInfo.initialSaleDate;
        idToEvent[id].initialDate = eventInfo.initialDate;
        idToEvent[id].finalDate = eventInfo.finalDate;

        emit EventItemModified(msg.sender, id, block.timestamp);
    }

    /**
     * $dev Deletes an event
     * $param id _id of the event
     **/
    function deleteEvent(uint256 id) public {
        //Needs to exist an event created with that id
        require(idToEvent[id]._id != 0, "This event does not exist");

        //The sender needs to be the creator of the event or be the contract owner
        require(
            idToEvent[id]._owner == msg.sender || msg.sender == owner(),
            "Invalid owner"
        );

        idToEvent[id].deleted = true;
        emit EventItemDeleted(msg.sender, id, block.timestamp);
    }

    /**
     * $dev Restores an event
     * $param id _id of the event
     **/
    function restoreEvent(uint256 id) public {
        //Needs to exist an event created with that id
        require(idToEvent[id]._id != 0, "This event does not exist");

        //The sender needs to be the creator of the event or be the contract owner
        require(idToEvent[id]._owner == msg.sender || msg.sender == owner(), "Invalid owner");

        idToEvent[id].deleted = false;
        emit EventItemRestored(msg.sender, id, block.timestamp);
    }

    /**
     * $dev Reads the event with the id specified if exists
     * $param id Id of the event to read
     * $param publicRead Indicates if it is a public petition
     * $return idToEvent[id] EventItem struct with the specified id
     */
    function readEvent(uint256 id, bool isPublicRead) public view returns (EventItem memory) {
        //Needs to exist an event created with that id
        require(idToEvent[id]._id != 0, "This event does not exist");

        if(isPublicRead == false){
            //The sender needs to be the creator of the event or be the contract owner
            require(idToEvent[id]._owner == msg.sender || msg.sender == owner(), "Invalid owner");
        }

        return idToEvent[id];
    }

    /**
     * $dev Reads all events from sender address
     * $param publicRead Indicates if it is a public petition
     * $return EventItem[] EventItem structs array with the events of the sender address
     */
    function readEvents(bool isPublicRead) public view returns (EventItem[] memory) {
        uint256 eventCount = _eventsIds.current();
        uint256 myEventCount = 0;
        uint256 currentIndex = 0;

        //Contract owner gets a counter of all the existing events
        //User gets a counters of all the events created by him
        for (uint256 i = 0; i < eventCount; i++) {
            //Checks the owner of the event
            if(idToEvent[i + 1]._owner == msg.sender || msg.sender == owner() || isPublicRead == true) {
                //Checks if the event is deleted or if the owner is the contract owner
                if(idToEvent[i + 1].deleted == false || msg.sender == owner()) {
                    myEventCount += 1;
                }
            }
        }

        EventItem[] memory events = new EventItem[](myEventCount);

        //Contract owner gets an array with all the events
        //User gets an array with the events created by him
        for (uint256 i = 0; i < eventCount; i++) {
            //Checks the owner of the event
            if(idToEvent[i + 1]._owner == msg.sender || msg.sender == owner() || isPublicRead == true) {
                //Checks if the event is deleted or if the owner is the contract owner
                if(idToEvent[i + 1].deleted == false || msg.sender == owner()) {
                    //Add event to the array
                    uint256 currentId = i + 1;
                    EventItem storage currentEvent = idToEvent[currentId];
                    events[currentIndex] = currentEvent;
                    currentIndex += 1;
                }
            }
        }

        return events;
    }

    // ----------------------- CAMPAIGNS FUNCTIONS -----------------------

    /**
     * $dev Creates a Campaign
     * $param idType Type of the campaign
     * $param eventId Id of the event
     * $param initialDate Date when the campaign starts
     * $param finalDate Date when the campaign ends
     * $param price Price of the campaign
     *
     **/
    function createCampaign(
        uint256 idType,
        uint256 eventId,
        uint256 initialDate,
        uint256 finalDate,
        uint256 price
    ) public payable {
        //The price needs to be equal to the amount the sender address sends.
        require(msg.value == price, "wrong amount sent");
        //Transfers the money to the contract owner address
        payable(owner()).transfer(msg.value);
        //Increments _campaignsIds global counter
        _campaignsIds.increment();
        uint256 campaignId = _campaignsIds.current();

        //Creates a new campaign and saves it in idToCampaign mapping at the campaignId position
        idToCampaign[campaignId] = CampaignItem(
            msg.sender,
            campaignId,
            idType,
            eventId,
            initialDate,
            finalDate,
            price,
            block.timestamp
        );

        //Adds the campaignId to the addressToIdCampaignArray mapping at the msg.sender position.
        addressToIdCampaignArray[msg.sender].push(campaignId);
        initialDateToIdCampaignArray[initialDate].push(campaignId);

        emit CampaignItemCreated(
            msg.sender,
            campaignId,
            idType,
            eventId,
            initialDate,
            finalDate,
            block.timestamp
        );
    }

    /**
     * $dev Reads all tickets from clients
     * $return TicketItem[] TicketItem structs array with all the tickets
     */
    function readCampaigns(bool isPublicRead) public view returns (CampaignItem[] memory) {
        uint256 campaignsCount = _campaignsIds.current();
        uint256 myCampaignsCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < campaignsCount; i++) {
            uint256 id = idToCampaign[i + 1].eventId;
            //Checks the owner of the event
            if(idToEvent[id]._owner == msg.sender || msg.sender == owner() || isPublicRead == true) {
                myCampaignsCount += 1;
            }
        }

        CampaignItem[] memory campaigns = new CampaignItem[](myCampaignsCount);

        //Contract owner gets an array with all the events
        //User gets an array with the events created by him
        for (uint256 i = 0; i < campaignsCount; i++) {
            uint256 id = idToCampaign[i + 1].eventId;
            //Checks the owner of the event
            if(idToEvent[id]._owner == msg.sender || msg.sender == owner() || isPublicRead == true) {
                //Add campaign to the array
                uint256 currentId = i + 1;
                CampaignItem storage currentCampaign = idToCampaign[currentId];
                campaigns[currentIndex] = currentCampaign;
                currentIndex += 1;
            }
        }

        return campaigns;
    }
}