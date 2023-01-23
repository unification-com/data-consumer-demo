// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// must import this in order for it to connect to the system and network.
import "@unification-com/xfund-router/contracts/lib/ConsumerBase.sol";

contract DemoConsumerCustom  is ConsumerBase, Ownable {

    // provider to use for data requests. Must be registered on Router
    address private provider;

    // default fee to use for data requests
    uint256 public fee;

    // map bytes32(BaseTarget) to current price
    mapping(bytes32 => uint256) public prices;

    // map request ID to the bytes32 representation of the endpoint sent in the request
    mapping(bytes32 => bytes32) private requests;

    // map bytes32 representation of an endpoint to hash of pair
    mapping(bytes32 => bytes32) private endpointPairLookup;

    // Will be called when data provider has sent data to the recieveData function
    event PriceDiff(bytes32 requestId, bytes32 pair, uint256 oldPrice, uint256 newPrice, int256 diff);

    /**
     * @dev constructor must pass the address of the Router and xFUND smart
     * contracts to the constructor of your contract! Without it, this contract
     * cannot interact with the system, nor request/receive any data.
     * The constructor calls the parent ConsumerBase constructor to set these.
     *
     * @param _router address of the Router smart contract
     * @param _xfund address of the xFUND smart contract
     * @param _provider address of the default provider
     * @param _fee uint256 default fee
     */
    constructor(address _router, address _xfund, address _provider, uint256 _fee)
    ConsumerBase(_router, _xfund) {
        provider = _provider;
        fee = _fee;
    }

    /**
     * @dev customRequestData - example custom end user function for requesting data.
     *      this wraps around the underlying ConsumerBase.sol's requestData function,
     *      and executes some pre- and post-processing of the data when requesting.
     *      Defining custom functions allows more flexibility, and potentially more
     *      sophisticated receiveData functions.
     *
     *      In this function, we're setting up our contract to be able to store
     *      data for multiple price pairs, and set up hooks to be able to act on them.
     *
     *      example call:
     *      customRequestData("BTC", "USD", 0x4254432e5553442e50522e415649, 0x611661f4B5D82079E924AcE2A6D113fAbd214b14, 100)
     *
     * @param _base string the base currency, e.g. BTC
     * @param _target string the target currency, e.g. USD
     * @param _endpoint bytes32 the target currency, e.g. USD
     */
    function customRequestData(
        string memory _base,
        string memory _target,
        bytes32 _endpoint)
    external onlyOwner {

        // store endpoint/pair lookup for using later in receiveData
        bytes32 pair = pairAsBytes32(_base, _target);
        endpointPairLookup[_endpoint] = pair;

        // call the underlying Consumer.sol lib's requestData function.
        // requestData returns the bytes32 request ID, which we can store and use later
        bytes32 requestId = _requestData(provider, fee, _endpoint);

        // store the request ID/endpoint lookup for use in the receiveData function etc.
        requests[requestId] = _endpoint;
    }

    /**
     * @dev setProvider change default provider. Uses OpenZeppelin's
     * onlyOwner modifier to secure the function.
     *
     * @param _provider address of the default provider
     */
    function setProvider(address _provider) external onlyOwner {
        provider = _provider;
    }

    /**
     * @dev setFee change default fee. Uses OpenZeppelin's
     * onlyOwner modifier to secure the function.
     *
     * @param _fee uint256 default fee
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * @dev increaseRouterAllowance allows the Router to spend xFUND on behalf of this
     * smart contract.
     *
     * NOTE: Calls the internal _increaseRouterAllowance function in ConsumerBase.sol.
     *
     * Required so that xFUND fees can be paid. Uses OpenZeppelin's onlyOwner modifier
     * to secure the function.
     *
     * @param _amount uint256 amount to increase
     */
    function increaseRouterAllowance(uint256 _amount) external onlyOwner {
        require(_increaseRouterAllowance(_amount));
    }

    /**
     * @dev setRouter allows updating the Router contract address
     *
     * NOTE: Calls the internal setRouter function in ConsumerBase.sol.
     *
     * Can be used if network upgrades require new Router deployments.
     * Uses OpenZeppelin's onlyOwner modifier to secure the function.
     *
     * @param _router address new Router address
     */
    function setRouter(address _router) external onlyOwner {
        require(_setRouter(_router));
    }

    /**
     * @dev increaseRouterAllowance allows contract owner to withdraw
     * any xFUND held in this contract.
     * Uses OpenZeppelin's onlyOwner modifier to secure the function.
     *
     * @param _to address recipient
     * @param _value uint256 amount to withdraw
     */
    function withdrawxFund(address _to, uint256 _value) external onlyOwner {
        require(xFUND.transfer(_to, _value), "Not enough xFUND");
    }

    /**
     * @dev recieveData - example end user function to receive data. This will be called
     * by the data provider, via the Router's fulfillRequest, and through the ConsumerBase's
     * rawReceiveData function.
     *
     * Our function will lookup for which pair the price is being supplied, and store it
     * accordingly. It then calculates the difference and emits a PriceDiff event. A
     * custom Oracle can monitor this event, and act accordingly - for example,
     * calling a rebase function within this smart contract, depending on if the
     * price has increased or decreased etc.
     *
     * @param _price uint256 result being sent
     * @param _requestId bytes32 request ID of the request being fulfilled
     */
    function receiveData(
        uint256 _price,
        bytes32 _requestId
    )
    internal override {

        // get the endpoint used in this request
        bytes32 endpoint = requests[_requestId];

        // get the pair the endpoint represents
        bytes32 pair = endpointPairLookup[endpoint];

        // get old price
        uint256 oldPrice = prices[pair];

        // optionally, do something and emit an event to the logs
        int256 diff = int256(_price) - int256(oldPrice);

        // perhaps a script is watching for this event, ready to
        // act and call another function in this contract.
        emit PriceDiff(_requestId, pair, oldPrice, _price, diff);

        // set the new price as sent by the provider
        prices[pair] = _price;

        // clean up
        delete requests[_requestId];
    }

    /**
     * @dev getPrice - return the current stored price for the given pair
     *
     * @param _base string the base currency, e.g. BTC
     * @param _target string the target currency, e.g. USD
     */
    function getPrice(string memory _base, string memory _target) external view returns(uint256 price) {
        bytes32 pair = pairAsBytes32(_base, _target);
        return prices[pair];
    }

    /**
     * @dev pairAsBytes32 - concatenate a pair string and return it as a bytes32 value
     *
     * @param _base string the base currency, e.g. BTC
     * @param _target string the target currency, e.g. USD
     * @return pair bytes32 converted pair value
     */
    function pairAsBytes32(string memory _base, string memory _target) internal pure returns(bytes32 pair) {
        bytes memory pairPacked = abi.encodePacked(_base, _target);
        assembly {
            pair := mload(add(pairPacked, 32))
        }
    }
}
