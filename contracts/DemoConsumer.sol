// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

// must import this in order for it to connect to the system and network.
import "@unification-com/xfund-router/contracts/lib/ConsumerBase.sol";

// Note the "is ConsumerBase", to extend
// https://github.com/unification-com/xfund-router/blob/main/contracts/lib/ConsumerBase.sol
// ConsumerBase.sol interfaces with the deployed ConsumerLib.sol library smart contract
// which itself contains most of the required logic for interacting with the system
contract DemoConsumer is ConsumerBase {

    // This variable will be modified by the data provider.
    // Must be a uint256
    uint256 public price;

    // Will be called when data provider has sent data to the recieveData function
    event PriceDiff(bytes32 requestId, uint256 oldPrice, uint256 newPrice, int256 diff);

    // Must pass the address of the Router smart contract to the constructor
    // of your contract! Without it, your contract cannot interact with the
    // system, nor request/receive any data.
    // The constructor calls the parent constructor
    // https://github.com/unification-com/xfund-router/blob/main/contracts/lib/ConsumerBase.sol#L46
    // which in turn initialises the contract with the ConsumerLib.sol library
    // https://github.com/unification-com/xfund-router/blob/main/contracts/lib/ConsumerLib.sol#L149
    constructor(address _router)
    ConsumerBase(_router) {
        price = 0;
    }

    /*
     * @dev recieveData - example end user function to receive data. This will be called
     * by the data provider, via the Router's fulfillRequest, and through the ConsumerBase's
     * rawReceiveData function.
     *
     * Note: The receiving function should not be too complex, in order to conserve gas.
     * As a minimum, it should accept the result and store it. Optionally, calculations
     * can be run, and events can be emitted for logging purposes.
     *
     * Note: validation of the data and data provider sending the data is handled
     * internally by the ConsumerBase.sol and ConsumerLib.sol smart contracts, allowing
     * devs to focus on pure functionality.
     *
     * @param _price uint256 result being sent
     * @param _requestId bytes32 request ID of the request being fulfilled
     */
    function receiveData(
        uint256 _price,
        bytes32 _requestId
    )
    internal override {
        // optionally, do something and emit an event to the logs
        int256 diff = int256(_price) - int256(price);
        emit PriceDiff(_requestId, price, _price, diff);

        // set the new price as sent by the provider
        price = _price;
    }
}
