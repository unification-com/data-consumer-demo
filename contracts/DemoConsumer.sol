// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@unification-com/xfund-router/contracts/lib/Consumer.sol";

contract DemoConsumer is Consumer {

    uint256 public price;

    // Can be called when data provider has sent data
    event GotSomeData(address router, bytes32 requestId, uint256 price);

    constructor(address _router)
    public Consumer(_router) {
        price = 0;
    }

    /*
     * @dev requestData - example end user function to start a data request.
     * Kicks off the Consumer.sol lib's submitDataRequest function which
     * forwards the request to the deployed Router smart contract
     *
     * Note: the  ConsumerLib.sol lib's submitDataRequest function has the onlyOwner()
     * and isProvider(_dataProvider) modifiers. These ensure only this contract owner
     * can initialise a request, and that the provider is authorised respectively.
     *
     * @param _dataProvider payable address of the data provider
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
     * been sent by the authorised data provider.
     *
     * Note: The receiving function should not be complex, in order to conserve gas. It should accept the
     * result validate it (using the isValidFulfillment modifier) and store it. Optionally, a simple
     * event can be emitted for logging. Finally, storage should be cleaned up by calling the
     * deleteRequest(_price, _requestId, _signature) function.
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
    isValidFulfillment(_requestId, _price, _signature)
    returns (bool success) {
        price = _price;
        emit GotSomeData(msg.sender, _requestId, _price);
        deleteRequest(_price, _requestId, _signature);
        return true;
    }
}
