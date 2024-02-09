// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./erc1111.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract DAN is ERC1111, IERC2981, Ownable{
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public withdrawn;

    bool public isRedirect;

    address private _royaltyRecipient;

    // metadata URI
    string private _baseTokenURI;

    mapping(address => bool) public isFairLaunch;

    // uint256 startTimestamp = 1707534671; // 2024-02-10 11:11:11
    uint256 startTimestamp = 0; // TODO test only


    constructor(
    ) ERC1111("pfpasia", "pfpasia", 18) {

    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
    
    function claim(uint256 _amount, bytes32[] calldata _proof) external {
        address _account = msg.sender;
        require(!withdrawn[_account], "withdrawned token.");

        // Verify the merkle proof.
        bytes32 leaf = keccak256(abi.encodePacked(_account, _amount));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof");

        withdrawn[_account] = true;

        for (uint256 i = 0; i < _amount;i++){
            ERC1111._mint(_account);
        }
    }

    function openRedirect() public onlyOwner {
        isRedirect = true;
    }

    function ftRedirectNFT(uint256 amount) public {
        require(isRedirect, "redirect not open");
        _ft_to_nft(amount);
    }
    function nftRedirectFT(uint256 tokenId) public {
        require(isRedirect, "redirect not open");
        _nft_to_ft(tokenId);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function fairLaunch() external{
        require(block.timestamp >= startTimestamp, "not start");
        require(!Address.isContract(msg.sender), "contract");
        require(!isFairLaunch[msg.sender],"claimed");
        require(totalSupply() + 10000 * 10**18 <= 5000 * 10000 * 10**18, "exceed");

        _mintFT(msg.sender, 10000 * 10**18);

        isFairLaunch[msg.sender] = true;

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

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }


     /**
   *  --------- IERC2981 ---------
   */

  function royaltyInfo(
    uint256 tokenId,
    uint256 salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    return (_royaltyRecipient, salePrice * 5 / 100);
  }

  function setRoyaltyRecipient(address r) public onlyOwner {
    _royaltyRecipient = r;
  }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId;
    }
   
}