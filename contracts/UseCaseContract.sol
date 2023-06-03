// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./CallOrderControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// AccessControl.sol is not used in this contract but here it is if
// you want to play with it. (:D)
import "@openzeppelin/contracts/access/AccessControl.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
 * @title Example of contract using CallOrderControl.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 *
 * @dev To use CallOrderControl make your contract inherits CallOrderControl, add the isAllowedCall()
 * modifier in the functions you desire to control when they are called.
 *
 * The isAllowedInteraction() has 2 parameters:
 *
 * -First = function selector of the function where it's being applied => bytes4(keccak256(bytes("funcSignatureAsString")))
 * -Second = msg.sender => to know who is calling.
 *
 * Implementation in code below.
 *
 * Btw it's essential you use abi.enconde() and not abi.encodePakced() because abi.encodePakced()
 * can give the same output to different inputs.
 *
 * @dev Additionally you can override and override the callAllowFuncCallsFor() function. if you please mixing this
 * CallOrderControl with, for example, other useful ones like Ownable or AccessControl contracts from OpenZeppelin.
 */
contract UseCaseContract is CallOrderControl, Ownable {
    uint256 private s_myData;

    function changeData(
        uint256 _newNumber
    )
        public
        isAllowedCall(
            bytes4(keccak256(bytes("changeData(uint256)"))), // <-- Look!
            msg.sender // <-- Look!
        )
    {
        s_myData = _newNumber;
    }

    function incrementData(
        uint256 _increment
    )
        public
        isAllowedCall(
            bytes4(keccak256(bytes("incrementData(uint256)"))), // <-- Look!
            msg.sender // <-- Look!
        )
    {
        s_myData += _increment;
    }

    function getNumber() public view returns (uint256) {
        return s_myData;
    }

    // Override if you please mixing the call control with useful
    // modifiers such as OpenZeppelin's onlyRole from AccessControl.sol
    // or onlyOwner from Owner.sol.
    function callAllowFuncCallsFor(
        address _callerAddress,
        bytes4[] calldata _validFuncCalls,
        bool _isSequence
    ) public override onlyOwner {
        allowFuncCallsFor(_callerAddress, _validFuncCalls, _isSequence);
    }
}
