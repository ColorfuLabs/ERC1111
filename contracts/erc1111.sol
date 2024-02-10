// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ERC1111 {

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event ERC20Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    // meatadata

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    // Token decimals
    uint8 public decimals;

    // erc20

    mapping(address => uint256) private _erc20BalanceOf;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    // erc721

    // Mapping owner address to token count
    mapping(address => uint256) private _erc721BalanceOf;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Array of owned ids in native representation
    mapping(address => uint256[]) internal _owned;

    mapping(uint256 => uint256) internal _ownedIndex;

    uint256 public minted;

    bool enableFtTransfer;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    )  {
        name =      name_;
        symbol = symbol_;
        decimals = decimals_;
    }


    function balanceOf(address owner) public view virtual returns (uint256) {
        return _erc20BalanceOf[owner];
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        require(_exists(tokenId), "ERC721: invalid token ID");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function approve(address spender, uint256 amountOrId) public virtual  {
        if (amountOrId <= minted && amountOrId > 0) {
            address owner = ownerOf(amountOrId);
            require(spender != owner, "ERC721: approval to current owner");
            require(
                msg.sender == owner || isApprovedForAll(owner, msg.sender),
                "ERC721: approve caller is not token owner or approved for all"
            );

            _tokenApprovals[amountOrId] = spender;

            emit Approval(owner, spender, amountOrId);
        } else {
            _allowances[msg.sender][spender] = amountOrId;

            emit Approval(msg.sender, spender, amountOrId);
        }

    }

    // erc20//
    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amountOrId
    ) public virtual {
        if (amountOrId <= minted) {
            require(_isApprovedOrOwner(msg.sender, amountOrId), "ERC721: caller is not token owner or approved");
            require(ownerOf(amountOrId) == from, "ERC721: transfer from incorrect owner");
            require(to != address(0), "ERC721: transfer to the zero address");

            delete _tokenApprovals[amountOrId];

            unchecked {
                _erc721BalanceOf[from] -= 1;
                _erc721BalanceOf[to] += 1;
            }

            _owners[amountOrId] = to;

            // update from
            uint256 updatedId = _owned[from][_owned[from].length - 1];
            _owned[from][_ownedIndex[amountOrId]] = updatedId;
            _owned[from].pop();
            _ownedIndex[updatedId] = _ownedIndex[amountOrId];
            _owned[to].push(amountOrId);
            _ownedIndex[amountOrId] = _owned[to].length - 1;

            emit Transfer(from, to, amountOrId);
        } else {
            uint256 allowed = _allowances[from][msg.sender];

            if (allowed != type(uint256).max)
                _allowances[from][msg.sender] = allowed - amountOrId;

            _transfer(from, to, amountOrId);
        }
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(enableFtTransfer, "can not transfer");
        uint256 fromBalance = _erc20BalanceOf[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _erc20BalanceOf[from] -= amount;
            _erc20BalanceOf[to] += amount;
        }

        emit ERC20Transfer(from, to, amount);
        return true;
    }

    function _mint(address to) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        unchecked {
            minted++;
        }
        uint256 tokenId = minted;

        unchecked {
            _erc721BalanceOf[to] += 1;
        }
        _owners[tokenId] = to;
        _owned[to].push(tokenId);
        _ownedIndex[tokenId] = _owned[to].length - 1;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(address owner) internal virtual {
        uint256 tokenId=_owned[owner][_owned[owner].length - 1];
        _owned[owner].pop();

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            _erc721BalanceOf[owner] -= 1;
        }
        delete _owners[tokenId];
        delete _ownedIndex[tokenId];

        emit Transfer(owner, address(0), tokenId);

    }

    function _mintFT(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _erc20BalanceOf[account] += amount;
        }
        emit ERC20Transfer(address(0), account, amount);

    }

    function _getUnit() internal view returns (uint256) {
        return 10000 * 10 ** decimals;
    }

    function _nft_to_ft(uint256 tokenId) internal {
        uint256 unit = _getUnit();
        transferFrom(msg.sender, address(this), tokenId);

        _erc20BalanceOf[msg.sender] += unit;
        _totalSupply += unit;

        emit ERC20Transfer(address(0), msg.sender, unit);
    }

    function _ft_to_nft(uint256 amount) internal {
        uint256 unit = _getUnit();
        uint256 nftAmount = amount / unit;
        uint256 ftAmount = nftAmount * unit;

        _transfer(msg.sender, address(0), ftAmount);
        _totalSupply -= ftAmount;

        uint256 nftMintAmount = _owned[address(this)].length < nftAmount ? nftAmount-_owned[address(this)].length : 0;
        uint256 nftTransferAmount= nftAmount - nftMintAmount;

        for (uint256 i=0; i<nftMintAmount; i++){
            _mint(msg.sender);
        }
        
        for (uint256 i=0; i<nftTransferAmount; i++){
            uint256 tokenId=_owned[address(this)][_owned[address(this)].length - 1];
            address from = address(this);
            address to = msg.sender;
            unchecked {
                _erc721BalanceOf[from] -= 1;
                _erc721BalanceOf[to] += 1;
            }

            _owners[tokenId] = to;

            // update from
            uint256 updatedId = _owned[from][_owned[from].length - 1];
            _owned[from][_ownedIndex[tokenId]] = updatedId;
            _owned[from].pop();
            _ownedIndex[updatedId] = _ownedIndex[tokenId];
            _owned[to].push(tokenId);
            _ownedIndex[tokenId] = _owned[to].length - 1;

            emit Transfer(from, to, tokenId);
        }
    }
    function tokenURI(uint256 id) public view virtual returns (string memory);

}