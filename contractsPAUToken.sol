pragma solidity ^0.5.11;

/*========================================================================================

SafeMath Library

========================================================================================*/


library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
    
    
}



/*========================================================================================

Ownable Library

========================================================================================*/


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/*========================================================================================

Mintable Library

========================================================================================*/

contract Mintable {
    mapping (address => bool) private _minters;
    address private _minteradmin;
    address public pendingMinterAdmin;


    modifier onlyMinterAdmin() {
        require (msg.sender == _minteradmin, "caller not a minter admin");
        _;
    }

    modifier onlyMinter() {
        require (_minters[msg.sender] == true, "can't perform mint");
        _;
    }

    modifier onlyPendingMinterAdmin() {
        require(msg.sender == pendingMinterAdmin);
        _;
    }

    event MinterTransferred(address indexed previousMinter, address indexed newMinter);

    constructor () internal {
        _minteradmin = msg.sender;
        _minters[msg.sender] = true;
    }

    function minteradmin() public view returns (address) {
        return _minteradmin;
    }

    function addToMinters(address account) public onlyMinterAdmin {
        _minters[account] = true;
    }

    function removeFromMinters(address account) public onlyMinterAdmin {
        _minters[account] = false;
    }

    function transferMinterAdmin(address newMinter) public onlyMinterAdmin {
        pendingMinterAdmin = newMinter;
    }

    function claimMinterAdmin() public onlyPendingMinterAdmin {
        emit MinterTransferred(_minteradmin, pendingMinterAdmin);
        _minteradmin = pendingMinterAdmin;
        pendingMinterAdmin = address(0);
    }
}

contract Pausable {
    bool private _paused;
    address private _pauser;
    address public pendingPauser;

    modifier onlyPauser() {
        require(msg.sender == _pauser, "caller is not a pauser");
        _;
    }

    modifier onlyPendingPauser() {
        require(msg.sender == pendingPauser);
        _;
    }

    event PauserTransferred(address indexed previousPauser, address indexed newPauser);


    constructor () internal {
        _paused = false;
        _pauser = msg.sender;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function pauser() public view returns (address) {
        return _pauser;
    }

    function pauseTrigger() public onlyPauser {
        _paused = !_paused;
    }

    function transferPauser(address newPauser) public onlyPauser {
        pendingPauser = newPauser;
    }

    function claimPauser() public onlyPendingPauser {
        emit PauserTransferred(_pauser, pendingPauser);
        _pauser = pendingPauser;
        pendingPauser = address(0);
    }
}

contract TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public;
}

contract PAUToken is  Ownable, Pausable, Mintable{
    using SafeMath for uint256;
    
    //MAX_SUPPLY
    uint256 public constant MAX_SUPPLY = 11000000;
    
    uint256 public constant INITIAL_COLATERAL = 200000;
    uint256 public constant Marketing = 2000000;
    uint256 public constant LIQUIDITY_MINING = 3000000;
    uint256 public constant TREASURY = 2000000;
    uint256 public constant TEAM = 600000;
    uint256 public constant AIRDROPS = 3000000;
    
    address public constant  _walletMarketing = 0xDc9111DB04cE2Db377A3cFAB7E6867Da17164e1c;
    address _walletLiquidityMining  = 0xDc9111DB04cE2Db377A3cFAB7E6867Da17164e1c;
    address _walletTreasury  = 0xDc9111DB04cE2Db377A3cFAB7E6867Da17164e1c;
    address _walletTeam  = 0xDc9111DB04cE2Db377A3cFAB7E6867Da17164e1c;
    address _walletAirdrops  = 0xDc9111DB04cE2Db377A3cFAB7E6867Da17164e1c;
    
    //variables
    string public name;
    string public symbol;
    uint8 public decimals;
    
    
    //mappings
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _buyonsale;
    mapping (address => uint256) private _amountonsale;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Freeze(address indexed from, uint256 amount);
    event Melt(address indexed from, uint256 amount);
    event MintFrozen(address indexed to, uint256 amount);
    event FrozenTransfer(address indexed from, address indexed to, uint256 value);

    constructor (string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        mint(msg.sender, INITIAL_COLATERAL);
        mint(_walletMarketing, Marketing);
        mint(_walletLiquidityMining, LIQUIDITY_MINING); 
        mint(_walletTreasury, TREASURY);
        mint(_walletTeam, TEAM);
        mint(_walletAirdrops, AIRDROPS);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(this), "can't transfer tokens to the contract address");
    
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(this), "can't transfer tokens to the contract address");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
       
        if(_buyonsale[msg.sender]){
            
        }else if(_buyonsale[msg.sender]){
            
        }else{
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(account != address(this), "ERC20: mint to the contract address");
        require(amount > 0, "ERC20: mint amount should be > 0");
        require((_totalSupply + amount) <= 0, "MAX_SUPPLY already reached");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(this), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(this), value);
    }
    


    function _approve(address _owner, address spender, uint256 value) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }

    function addToSale(address ad, uint256 amount) external{
       _addToSale( ad,  amount);
    }
    
    function _addToSale(address ad, uint256 amount) internal{
         require(ad == msg.sender, "Not sender");
         
        if(!_buyonsale[ad]){
             _buyonsale[ad] = true;
        }
        _amountonsale[ad].add(amount);
        
    }

}

/*========================================================================================

Crowdsale

========================================================================================*/


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    PAUToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;

    uint256 public endTime;

    // address where funds are collected
    address payable wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    /**
     * event for token purchase logging
     * @param beneficiary who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address beneficiary, uint256 value, uint256 amount);

    constructor(uint256 _startTime, uint256 _rate, address _wallet, PAUToken _token) public {
        require(_startTime >= now);
        require(_rate > 0);
        require(_wallet != address(0));

        startTime = _startTime;
        endTime = _startTime.add(50 days);
        rate = _rate;
        wallet = msg.sender;
        token = _token;
    }

    // fallback function can be used to buy tokens
    function() external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(getRate());

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        emit TokenPurchase(beneficiary,  weiAmount, tokens);

        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    // @return the crowdsale rate
    function getRate() public view returns (uint256) {
        return rate;
    }


}


/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }
}
contract PAUCrowdsale is FinalizableCrowdsale {

    // =================================================================================================================
    //                                      Constants
    // =================================================================================================================
    // Max amount of known addresses of which will get SRN by 'Grant' method.
    //
    // grantees addresses will be SirinLabs wallets addresses.
    // these wallets will contain SRN tokens that will be used for 2 purposes only -
    // 1. SRN tokens against raised fiat money
    // 2. SRN tokens for presale bonus.
    // we set the value to 10 (and not to 2) because we want to allow some flexibility for cases like fiat money that is raised close to the crowdsale.
    // we limit the value to 10 (and not larger) to limit the run time of the function that process the grantees array.
    uint8 public constant MAX_TOKEN_GRANTEES = 10;

    // SRN to ETH base rate
    uint256 public constant EXCHANGE_RATE = 500;


    // =================================================================================================================
    //                                      Modifiers
    // =================================================================================================================

    /**
     * @dev Throws if called not during the crowdsale time frame
     */
    modifier onlyWhileSale() {
        require(isActive());
        _;
    }

    // Funds collected outside the crowdsale in wei
    uint256 public fiatRaisedConvertedToWei;

    //Grantees - used for non-ether and presale bonus token generation
    address[] public presaleGranteesMapKeys;
    mapping (address => uint256) public presaleGranteesMap;  //address=>wei token amount



    // =================================================================================================================
    //                                      Events
    // =================================================================================================================

    event FiatRaisedUpdated(address _address, uint256 _fiatRaised);

    event TokenPurchaseWithGuarantee(address beneficiary, uint256 value, uint256 amount);

    // =================================================================================================================
    //                                      Constructors
    // =================================================================================================================

    constructor(uint256 _startTime,  address _wallet, PAUToken _PAUToken)
    public
    Crowdsale(_startTime, EXCHANGE_RATE, _wallet, _PAUToken) {

        token = _PAUToken;
    }

    // =================================================================================================================
    //                                      Impl Crowdsale
    // =================================================================================================================

    // @return the rate in SRN per 1 ETH according to the time of the tx and the SRN pricing program.
    // @Override
    function getRate() public view returns (uint256) {
        if (now < (startTime.add(24 hours))) {return 2000;}
        if (now < (startTime.add(2 days))) {return 950;}
        if (now < (startTime.add(3 days))) {return 900;}
        if (now < (startTime.add(4 days))) {return 855;}
        if (now < (startTime.add(5 days))) {return 810;}
        if (now < (startTime.add(6 days))) {return 770;}
        if (now < (startTime.add(7 days))) {return 730;}
        if (now < (startTime.add(8 days))) {return 690;}
        if (now < (startTime.add(9 days))) {return 650;}
        if (now < (startTime.add(10 days))) {return 615;}
        if (now < (startTime.add(11 days))) {return 580;}
        if (now < (startTime.add(12 days))) {return 550;}
        if (now < (startTime.add(13 days))) {return 525;}

        return rate;
    }

    // =================================================================================================================
    //                                      Impl FinalizableCrowdsale
    // =================================================================================================================

    //@Override
    function finalization() internal onlyOwner {
        super.finalization();

        // transfer token ownership to crowdsale owner
        token.transferOwnership(owner);

    }

    // =================================================================================================================
    //                                      Public Methods
    // =================================================================================================================
    // @return the total funds collected in wei(ETH and none ETH).
    function getTotalFundsRaised() public view returns (uint256) {
        return fiatRaisedConvertedToWei.add(weiRaised);
    }

    // @return true if the crowdsale is active, hence users can buy tokens
    function isActive() public view returns (bool) {
        return now >= startTime && now < endTime;
    }

    // =================================================================================================================
    //                                      External Methods
    // =================================================================================================================


    // @dev Set funds collected outside the crowdsale in wei.
    //  note: we not to use accumulator to allow flexibility in case of humane mistakes.
    // funds are converted to wei using the market conversion rate of USD\ETH on the day on the purchase.
    // @param _fiatRaisedConvertedToWei number of none eth raised.
    function setFiatRaisedConvertedToWei(uint256 _fiatRaisedConvertedToWei) external onlyOwner onlyWhileSale {
        fiatRaisedConvertedToWei = _fiatRaisedConvertedToWei;
        emit FiatRaisedUpdated(msg.sender, fiatRaisedConvertedToWei);
    }


    // @dev Buy tokes with guarantee
    function buyTokensWithGuarantee() public payable {
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(getRate());

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(msg.sender, tokens);
        
        token.addToSale(msg.sender, tokens);

        emit TokenPurchaseWithGuarantee(msg.sender, weiAmount, tokens);
    }
}
