pragma solidity 0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract AdminRole {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor () internal {
        _addAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @title Freezable ERC20 token
 *
 * @dev All tokens are transferable, unless token holder address is frozen by an admin.
 */
contract FreezableToken is ERC20Detailed, AdminRole {
    mapping(address => bool) public frozen;
    event Freeze(address indexed account);
    event Unfreeze(address indexed account);

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, unless that account is frozen.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal {
        require(!frozen[account]);
        super._burn(account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, unless that account is frozen, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
    */
    function _burnFrom(address account, uint256 value) internal {
        require(!frozen[account]);
        super._burn(account, value);
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return !frozen[from] && !frozen[to] && super.transferFrom(from, to, value);
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return true, unless the sender or the receiver are frozen or the transfer did not happen.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        return !frozen[msg.sender] && !frozen[to] && super.transfer(to, value);
    }

    /**
    * @dev Admin-only function used to toggle the frozen status of an account.
    * Emits a Freeze event with the account address.
    * @param _address The address of the account.
    * @param _setFrozen bool value if the account's frozen flag should raised.
    */
    function toggleFreeze(address _address, bool _setFrozen) public onlyAdmin {
        if(frozen[_address] && !_setFrozen) {
            frozen[_address] = _setFrozen;
            emit Unfreeze(_address);
        } else if(!frozen[_address] && _setFrozen) {
            frozen[_address] = _setFrozen;
            emit Freeze(_address);
        }
    }
}

/**
* @dev This contract facilitates the creation of up to 60 sub-tokens whose function is:
*   - to allow the investors of the same deployment to be able to trade the sub-token
*       for that particular deployment only for tokens of the same sub-token
*   - to allow one account address to own sub-tokens from different deployments
*   - to enable the the sub-token holders to easily track their holdings
        through an explorer like Etherscan
    - to facilitate a 6-month lock up period
    - to let the sub-token holders redeem their holdings for the main-token once the
        lock up period is over
    - the sub-tokens holders are not eligible to receive the dividend that is paid
        only to the main-token holders
*/
contract SlicDeploymentToken is ERC20Detailed {
    uint256 public unlockTime = 0;
    uint8 public id;
    address public slicToken;

    /**
    * @dev Creates the sub-token for a particular deployment. The constructor must be
    *   called from inside the token contract so the sub-token admin functions can
    *   later be called only by the main-token admins.
    * @param _id The ID of the deployment, between 1 and 60.
    * @param _mintAmount The total amount of sub-tokens to be minted.
    */
    constructor(uint8 _id, uint256 _mintAmount) public
                ERC20Detailed(concat("SLiC Deployment Token ", _id), concat("SLIC", _id), 18) {
        require(_id > 0 && _id <= 60, "Invalid deployment ID");
        id = _id;
        slicToken = msg.sender;
        _mint(slicToken, _mintAmount);
    }

    /**
    * @dev an internal helper function used to dynamically construct the name and symbol
    *   of the sub-tokens
    * @param str The prefix of the result string.
    * @param _id The suffix of the result string.
    */
    function concat(string memory str, uint8 _id) internal pure returns (string memory) {
        uint8 digit1 = _id / 10;
        uint8 digit2 = _id % 10;
        bytes memory b = bytes(str);
        bytes memory newstrbytes = bytes(new string(b.length + 2));
        for (uint8 i = 0; i < b.length; i++) newstrbytes[i] = b[i];
        newstrbytes[b.length] = byte(48 + digit1);
        newstrbytes[b.length + 1] = byte(48 + digit2);
        return string(newstrbytes);
    }

    /**
    * @dev A helper method facilitating the swap of sub and main tokens and the
    *   burning of the no longer needed sub-tokens. Should not be called directly.
    *   Fails if the lock up has not yet started or is not over yet.
    * @param account The address of the account for which the redeem is happening.
    */
    function redeem(address account) public {
        require(msg.sender == slicToken, "This method should not be called directly");
        require(unlockTime != 0, "Lockup countdown has not started yet");
        require(now > unlockTime, "Lockup countdown has not finished yet");

        uint256 balance = balanceOf(account);
        if(balance > 0) {
            _burn(account, balance);
            IERC20(slicToken).transfer(account, balance);
        }
    }

    /**
    * @dev An admin-only function used to initialize the lock up countdown.
    *   Should not be called directly.
    */
    function startLockUpCountdown() public {
        require(msg.sender == slicToken, "This method should not be called directly");
        require(unlockTime == 0, "Lockup countdown already started");
        unlockTime = now + 182 days;
    }
}


/**
 * @title MultiSigAdmin
 * @dev A contract that does simple 2/3 multisig calls for the SLiC admin calls
 */
contract MultiSigAdmin {
    address public admin1;
    address public admin2;
    address public admin3;
    SlicToken public token;

    mapping(uint256 => ActionProposal) proposalsByBlock;

    /**
    * @dev either of the three admins can perform this action
    */
    modifier onlyAdmin() {
        require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3);
        _;
    }

    /**
    * @dev A struct helper storing the action, its proposer and the proposed params
    */
    struct ActionProposal {
        uint256 actionType;
        address proposer;
        address addressParam;
        bool boolParam;
    }

    /**
    * @dev Creates the multisig wallet contract. Should be called from the
    *   Slic main token, not directly.
    */
    constructor(address _admin1, address _admin2, address _admin3) public {
        admin1 = _admin1;
        admin2 = _admin2;
        admin3 = _admin3;
        token = SlicToken(msg.sender);
    }

    /**
    * @dev Multisig wrapper for the toggleFreeze function.
    * @param _address The address of the account.
    * @param _setFrozen bool value if the account's frozen flag should raised.
    * @param _proposalBlock Should be 0 if the caller is making a new proposal
    *   and if confirming a proposal, should be the number of the block at which
    *   the proposer made their action proposal.
    */
    function toggleFreeze(address _address, bool _setFrozen, uint256 _proposalBlock) public onlyAdmin {
        if(_proposalBlock != 0) {
            ActionProposal memory action = proposalsByBlock[_proposalBlock];
            if(action.proposer != address(0) && action.proposer != msg.sender && action.actionType == 1) {
                require(action.addressParam == _address && action.boolParam == _setFrozen);

                proposalsByBlock[_proposalBlock] = ActionProposal(0, address(0), address(0), false);
                token.toggleFreeze(action.addressParam, action.boolParam);
            }
        } else {
            require(proposalsByBlock[block.number].proposer == address(0));

            ActionProposal memory action = ActionProposal(1, msg.sender, _address, _setFrozen);
            proposalsByBlock[block.number] = action;
        }
    }

    /**
    * @dev Multisig wrapper for the recoverERC20Tokens function.
    * @param _address The address of the ERC20 token contract.
    * @param _proposalBlock Should be 0 if the caller is making a new proposal
    *   and if confirming a proposal, should be the number of the block at which
    *   the proposer made their action proposal.
    */
    function recoverERC20Tokens(address _address, uint256 _proposalBlock) public onlyAdmin {
        if(_proposalBlock != 0) {
            ActionProposal memory action = proposalsByBlock[_proposalBlock];
            if(action.proposer != address(0) && action.proposer != msg.sender && action.actionType == 2) {
                require(action.addressParam == _address);

                proposalsByBlock[_proposalBlock] = ActionProposal(0, address(0), address(0), false);
                token.recoverERC20Tokens(action.addressParam);
                IERC20(action.addressParam).transfer(msg.sender, IERC20(action.addressParam).balanceOf(address(this)));
            }
        } else {
            require(proposalsByBlock[block.number].proposer == address(0));

            ActionProposal memory action = ActionProposal(2, msg.sender, _address, false);
            proposalsByBlock[block.number] = action;
        }
    }

    /**
    * @dev Multisig wrapper for the addAdmin function.
    * @param _address The address of the address that will NOT be added as a multisig admin,
    *   it is rather added as an independent admin along the multisig wallet.
    * @param _proposalBlock Should be 0 if the caller is making a new proposal
    *   and if confirming a proposal, should be the number of the block at which
    *   the proposer made their action proposal.
    */
    function addAdmin(address _address, uint256 _proposalBlock) public onlyAdmin {
        if(_proposalBlock != 0) {
            ActionProposal memory action = proposalsByBlock[_proposalBlock];
            if(action.proposer != address(0) && action.proposer != msg.sender && action.actionType == 3) {
                require(action.addressParam == _address);

                proposalsByBlock[_proposalBlock] = ActionProposal(0, address(0), address(0), false);
                token.addAdmin(action.addressParam);
            }
        } else {
            require(proposalsByBlock[block.number].proposer == address(0));

            ActionProposal memory action = ActionProposal(3, msg.sender, _address, false);
            proposalsByBlock[block.number] = action;
        }
    }

    /**
    * @dev Multisig wrapper for the renounceAdmin function.
    *   WARNING: This is like a self-destruct function for the multisig admin wallet!
    *
    * @param _proposalBlock Should be 0 if the caller is making a new proposal
    *   and if confirming a proposal, should be the number of the block at which
    *   the proposer made their action proposal.
    */
    function renounceAdmin(uint256 _proposalBlock) public onlyAdmin {
        if(_proposalBlock != 0) {
            ActionProposal memory action = proposalsByBlock[_proposalBlock];
            if(action.proposer != address(0) && action.proposer != msg.sender && action.actionType == 4) {
                proposalsByBlock[_proposalBlock] = ActionProposal(0, address(0), address(0), false);
                token.renounceAdmin();
            }
        } else {
            require(proposalsByBlock[block.number].proposer == address(0));

            ActionProposal memory action = ActionProposal(4, msg.sender, address(0), false);
            proposalsByBlock[block.number] = action;
        }
    }
}

/**
 * @title SLiC token
 * @dev The main token.
 */
contract SlicToken is FreezableToken {
    mapping(uint8 => SlicDeploymentToken) public deploymentTokens;
    address public icoManager;
    address public admin1;
    address public admin2;
    address public admin3;
    MultiSigAdmin public multiSigAdmin;

    modifier onlyIcoManager() {
        require(msg.sender == icoManager);
        _;
    }

    /**
    * @dev Creates the main token and the multisig wallet. Should be called by the ICO manager.
    * @param _admin1, _admin2, _admin3 The addresses of the three accounts of the
    *   multisig admin wallet.
    */
    constructor(address _admin1, address _admin2, address _admin3) public ERC20Detailed("SLiC", "SLIC", 18) {
        require(_admin1 != address(0), "null admin1 address");
        require(_admin2 != address(0), "null admin2 address");
        require(_admin3 != address(0), "null admin3 address");
        require(_admin1 != _admin2 && _admin2 != _admin3 && _admin1 != _admin3, "duplicate admin addresses");

        admin1 = _admin1;
        admin2 = _admin2;
        admin3 = _admin3;

        icoManager = msg.sender;
    }

    /**
    * @dev Initializes the multisig admin with the three addresses supplied at the creation
    *   of this token contract. Cannot be called a second time unless the ICO manager address
    *   is given admin role again. Calling it a second time creates an identical multisig wallet
    *   with the same initial three admin addresses.
    */
    function initMultisigAdmin() public onlyIcoManager {
        multiSigAdmin = new MultiSigAdmin(admin1, admin2, admin3);
        addAdmin(address(multiSigAdmin));
        renounceAdmin();
    }

    /**
    * @dev An ICO manager-only function used to sequentially create the deployment sub-tokens.
    *   The number of tokens per sub-tokens is defined in the table in the README.md file.
    * @param deploymentId a number between 1 and 60
    */
    function createDeploymentToken(uint8 deploymentId) public onlyIcoManager {
        require(deploymentId > 0 && deploymentId <= 60, "Invalid deployment ID");
        require(address(deploymentTokens[deploymentId]) == address(0), "Deployment already created");
        require(deploymentId == 1 || address(deploymentTokens[deploymentId - 1]) != address(0), "Deployment creation should be sequential");

        uint256 mintAmount;
        if(deploymentId == 1) {
            mintAmount = 16429638 * (10 ** uint256(decimals()));
        } else if (deploymentId <= 10) {
            mintAmount = 12500000 * (10 ** uint256(decimals()));
        } else if (deploymentId <= 20) {
            mintAmount = 9765625 * (10 ** uint256(decimals()));
        } else if (deploymentId <= 40) {
            mintAmount = 7812500 * (10 ** uint256(decimals()));
        } else if (deploymentId <= 60) {
            mintAmount = 6250000 * (10 ** uint256(decimals()));
        }

        deploymentTokens[deploymentId] = new SlicDeploymentToken(deploymentId, mintAmount);
        _mint(address(deploymentTokens[deploymentId]), mintAmount);
    }

    /**
    * @dev A user function that lets them redeem the sub-tokens for the main token.
    * @param deploymentId the ID of the deployment sub-token
    */
    function redeemUnlockedTokens(uint8 deploymentId) public {
        deploymentTokens[deploymentId].redeem(msg.sender);
    }

    /**
    * @dev An ICO manager-only function that lets the ICO manager redeem the sub-tokens on behalf
    *   of a specific user.
    * @param deploymentId the ID of the deployment sub-token
    * @param account The address of the user account on the behalf of which the tokens are redeemed
    */
    function forceRedeemUnlockedTokens(uint8 deploymentId, address account) public onlyIcoManager {
        deploymentTokens[deploymentId].redeem(account);
    }

    /**
    * @dev An ICO manager-only function that lets the ICO manager distribute the already minted
    *   sub-tokens to the investors.
    */
    function distribute(address to, uint256 amount, uint8 deploymentId) public onlyIcoManager {
        deploymentTokens[deploymentId].transfer(to, amount);
    }

    /**
    * @dev An ICO manager-only function that lets the ICO manager start the lock up countdown
    *   for a deployment whose hard cap was reached.
    * @param deploymentId the ID of the deployment sub-token
    */
    function startLockUpCountdown(uint8 deploymentId) public onlyIcoManager {
        deploymentTokens[deploymentId].startLockUpCountdown();
    }

    /**
    * @dev An admin-only function that lets the admin extract any mistakenly sent tokens to this
    * smart contract address.
    * @param _contractAddress The address of the ERC20 token contract.
    */
    function recoverERC20Tokens(address _contractAddress) public onlyAdmin {
        IERC20 erc20Token = IERC20(_contractAddress);
        require(erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this))), "Token transfer/recovery failed");
    }
}
