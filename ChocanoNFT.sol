//////////////////////////////////////////////////////////////////////////////////////////////
///░█████╗░██╗░░██╗░█████╗░░█████╗░░█████╗░███╗░░██╗░█████╗░  ███╗░░██╗███████╗████████╗//////
///██╔══██╗██║░░██║██╔══██╗██╔══██╗██╔══██╗████╗░██║██╔══██╗  ████╗░██║██╔════╝╚══██╔══╝//////
///██║░░╚═╝███████║██║░░██║██║░░╚═╝███████║██╔██╗██║██║░░██║  ██╔██╗██║█████╗░░░░░██║░░░//////
///██║░░██╗██╔══██║██║░░██║██║░░██╗██╔══██║██║╚████║██║░░██║  ██║╚████║██╔══╝░░░░░██║░░░//////
///╚█████╔╝██║░░██║╚█████╔╝╚█████╔╝██║░░██║██║░╚███║╚█████╔╝  ██║░╚███║██║░░░░░░░░██║░░░//////
///░╚════╝░╚═╝░░╚═╝░╚════╝░░╚════╝░╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░  ╚═╝░░╚══╝╚═╝░░░░░░░░╚═╝░░░//////
//////////////////////////////////////////////////////////////////////////////////////////////
//////Project leader:  Eduardo Chocano
//////Project Advisor and Developer: Lenin Tarrillo
//////////////////////////////////////////////////////////////////////////////////////////////

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CoffeeEveryMorningNFT is ERC721Enumerable, AccessControl, Pausable {
    bytes32 public constant ADVISOR_ROLE = keccak256("ADVISOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bool public saleActive = false;
    bool public aproveWithdrawFunds = false;
    bool public aproveReturnfunds = false;

    // Reserved for the team, customs, giveaways, collabs and so on.
    uint256 public reserved = 15;

    // Price of each token
    uint256 public initial_price = 1 ether;
    uint256 public price;


    // Maximum limit of tokens that can ever exist
    uint256 public constant MAX_SUPPLY = 500;
    uint256 public constant MAX_MINT_PER_TX = 5;

    string public baseTokenURI =
        "https://cyan-big-hippopotamus-597.mypinata.cloud/ipfs/QmctBFb7gx1sZZMoAj4GEdmdUbMjRc1etB7z6insT3GtjX/0#";

    string public _WhitePaperURI = "";

    address public chocanoNFTAddress;

    constructor()
        ERC721("The Coffee Every Morning NFT", "COF")
    {
        price = initial_price;
        _setupRole(ADVISOR_ROLE, _msgSender());
       
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    
    function returnFunds(address holder) public whenNotPaused {
        require(
            aproveReturnfunds,
            "The Advisor has not activated the return of funds"
        );

        uint256 tokenCount = balanceOf(holder);
        uint256 tokenID = 0;

        for (uint256 i; i < tokenCount; i++) {
            tokenID = tokenOfOwnerByIndex(holder, i);
            _beforeTokenTransfer(holder, address(0), tokenID, 0);
        }
        payable(holder).transfer(initial_price * tokenCount);
    }

    // Standard mint function
    function mintToken(uint256 _amount) public payable whenNotPaused {
        uint256 supply = totalSupply();
        require(saleActive, "Sale isn't active");
        require(
            _amount > 0 && _amount <= MAX_MINT_PER_TX,
            "Can only mint between 1 and 10 tokens at once"
        );
        require(
            supply + _amount <= MAX_SUPPLY,
            "Can't mint more than max supply"
        );
        require(msg.value == price * _amount, "Wrong amount of ETH sent");
        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // Admin minting function to reserve tokens for the team, collabs, customs and giveaways
    function mintReserved(uint256 _amount) public onlyRole(ADMIN_ROLE) {
        // Limited to a publicly set amount
        require(_amount <= reserved, "Can't reserve more than set amount");
        reserved -= _amount;
        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // Start and stop sale
    function setSaleActive(bool val) public onlyRole(ADVISOR_ROLE) {
        saleActive = val;
    }

    // Activate the withdrawal of collected funds
    function setAproveWithdrawFunds() public onlyRole(ADVISOR_ROLE) {
        aproveWithdrawFunds = true;
    }

    // Activate the return of funds
    function setAproveReturnfunds() public onlyRole(ADVISOR_ROLE) {
        aproveReturnfunds = true;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyRole(ADVISOR_ROLE) {
        baseTokenURI = baseURI;
    }

    // Set WhitePaper Uri
    function setWhitePaperUri(string memory uri) public onlyRole(ADVISOR_ROLE) {
        _WhitePaperURI = uri;
    }

    function setPrice(uint256 newPrice ) public onlyRole(ADVISOR_ROLE) {
        price = newPrice;
    }

    function setChocanoAddress(address _chocano) public onlyRole(ADVISOR_ROLE) {
        chocanoNFTAddress = _chocano;
        _setupRole(ADMIN_ROLE, _chocano);
    }

    function withdrawFunds(uint256 amount) public payable onlyRole(ADMIN_ROLE) {
        require(
            aproveWithdrawFunds,
            "The Advisor has not authorized the withdrawal of the fund"
        );
        require(payable(chocanoNFTAddress).send(amount));
    }

    function pause() public onlyRole(ADVISOR_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADVISOR_ROLE) {
        _unpause();
    }

    function whitepaperUri() public view returns (string memory) {
        return _WhitePaperURI;
    }


    function underlyingAsset() public pure virtual returns (string memory) {
        return
            "Each NFT represents a physical copy of the collection of poems"
            "The Coffee of Every Morning signed by Eduardo Chocano."
            "In addition, the holder of the NFT is entitled to one hour of legal advice," 
            "the same that can be claimed after Eduardo Chocano's graduation.";
            
    }
    function chocano() public pure virtual returns (string memory) {
        return
            "Eduardo Jesus Chocano Ravida"
            "https://www.linkedin.com/in/eduardo-jesus-chocano-ravina-9611541b6/";
    }

    function advisor() public pure virtual returns (string memory) {
        return
            "Lenin Tarrillo Vilchez"
            "https://www.linkedin.com/in/lenintv/";
    }

    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
