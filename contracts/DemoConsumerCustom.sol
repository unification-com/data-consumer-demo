// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// must import this in order for it to connect to the system and network.
import "@unification-com/xfund-router/contracts/lib/ConsumerBase.sol";

contract DemoConsumerCustom  is ConsumerBase {

    // map bytes32(BaseTarget) to current price
    mapping(bytes32 => uint256) public prices;

    // map request ID to the bytes32 representation of the endpoint sent in the request
    mapping(bytes32 => bytes32) private requests;

    // map bytes32 representation of an endpoint to hash of pair
    mapping(bytes32 => bytes32) private endpointPairLookup;

    // Will be called when data provider has sent data to the recieveData function
    event PriceDiff(bytes32 requestId, bytes32 pair, uint256 oldPrice, uint256 newPrice, int256 diff);

    // Must pass the address of the Router smart contract to the constructor
    // of your contract! Without it, your contract cannot interact with the
    // system, nor request/receive any data.
    // The constructor calls the parent constructor
    // https://github.com/unification-com/xfund-router/blob/main/contracts/lib/ConsumerBase.sol#L46
    // which in turn initialises the contract with the ConsumerLib.sol library
    // https://github.com/unification-com/xfund-router/blob/main/contracts/lib/ConsumerLib.sol#L149
    constructor(address _router) public ConsumerBase(_router) { }

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
     * @param _dataProvider payable address of the data provider
     * @param _gasPrice uint256 max gas price consumer is willing to pay for data fulfilment, in gwei
     */
    function customRequestData(
        string memory _base,
        string memory _target,
        bytes32 _endpoint,
        address payable _dataProvider,
        uint256 _gasPrice)
    external {

        // store endpoint/pair lookup for using later in receiveData
        bytes32 pair = pairAsBytes32(_base, _target);
        endpointPairLookup[_endpoint] = pair;

        // call the underlying Consumer.sol lib's requestData function.
        // requestData returns the bytes32 request ID, which we can store and use later
        bytes32 requestId = requestData(_dataProvider, _endpoint, _gasPrice);

        // store the request ID/endpoint lookup for use in the receiveData function etc.
        requests[requestId] = _endpoint;
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
