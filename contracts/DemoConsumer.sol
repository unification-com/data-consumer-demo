// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// must import this in order for it to connect to the system and network.
import "@unification-com/xfund-router/contracts/lib/Consumer.sol";

// Note the "is Consumer", to extend
// https://github.com/unification-com/xfund-router/blob/main/contracts/lib/Consumer.sol
// Consumer.sol interfaces with the deployed ConsumerLib.sol library smart contract
// which itself contains most of the required logic for interating with the system
contract DemoConsumer is Consumer {

    // This variable will be modified by the data provider.
    // Must be a uint256
    uint256 public price;

    // Will be called when data provider has sent data to the recieveData function
    event GotSomeData(address router, bytes32 requestId, uint256 price);

    // Must pass the address of the Router smart contract to the constructor
    // of your contract! Without it, your contract cannot interact with the
    // system, nor request/receive any data.
    // The constructor calls the parent constructor
    // https://github.com/unification-com/xfund-router/blob/main/contracts/lib/Consumer.sol#L50
    // which in turn initialises the contract with the ConsumerLib.sol library
    // https://github.com/unification-com/xfund-router/blob/main/contracts/lib/ConsumerLib.sol#L65
    constructor(address _router)
    public Consumer(_router) {
        price = 0;
    }

    /*
     * @dev requestData - example end user function to initialise a data request.
     * Kicks off the underlying Consumer.sol's submitDataRequest function
     * https://github.com/unification-com/xfund-router/blob/main/contracts/lib/Consumer.sol#L163
     * (linked to the ConsumerLib.sol's submitDataRequest function)
     * https://github.com/unification-com/xfund-router/blob/main/contracts/lib/ConsumerLib.sol#L245
     * which forwards the request to the deployed Router smart contract
     *
     * Note: the  ConsumerLib.sol lib's submitDataRequest function has the onlyOwner()
     * and isProvider(_dataProvider) modifiers. These ensure only this contract owner
     * can initialise a request, and that the provider is authorised respectively.
     *
     * @param _dataProvider payable wallet address of the data provider
     * @param _data bytes32 value of data being requested, e.g. BTC.GBP.PRC.AVG requests average price for BTC/GBP pair
     * @param _gasPrice uint256 max gas price consumer is willing to pay, in gwei. * (10 ** 9) conversion
     *        is done automatically within the Consumer.sol lib's submitDataRequest function
     * @return requestId bytes32 request ID which can be used to track/cancel the request
     */
    function requestData(
        address payable _dataProvider,
        bytes32 _data,
        uint256 _gasPrice)
    public returns (bytes32 requestId) {
        // call the underlying Consumer.sol's submitDataRequest function
        return submitDataRequest(_dataProvider, _data, _gasPrice, this.recieveData.selector);
    }

    /*
     * @dev recieveData - example end user function to recieve data. This will be called
     * by the data provider, via the Router's fulfillRequest function.
     *
     * Important: The isValidFulfillment modifier is used to validate the request to ensure it has indeed
     * been sent by the authorised data provider. Without it, potentially anyone can submit
     * arbitrary data, so it's important to include this modifier!
     *
     * Note: The receiving function should not be complex, in order to conserve gas. It should accept the
     * result, validate it (using the isValidFulfillment modifier) and store it. Optionally, a simple
     * event can be emitted for logging purposes. Finally, storage should be cleaned up by calling the
     * deleteRequest(_price, _requestId, _signature) function, to reduce the contract's storage used.
     *
     * @param _price uint256 result being sent
     * @param _requestId bytes32 request ID of the request being fulfilled
     * @param _signature bytes signature of the data and request info. Signed by provider to ensure only the provider
     *        has sent the data
     * @return requestId bytes32 request ID which can be used to track/cancel the request
     */
    function recieveData(
        uint256 _price,
        bytes32 _requestId,
        bytes memory _signature
    )
    external
    // Important: include this modifier!
    isValidFulfillment(_requestId, _price, _signature)
    returns (bool success) {
        // set the new price as sent by the provider
        price = _price;

        // optionally emit an event to the logs
        emit GotSomeData(msg.sender, _requestId, _price);

        // clean up the request ID - it's no longer required to be stored.
        deleteRequest(_price, _requestId, _signature);
        return true;
    }
}
