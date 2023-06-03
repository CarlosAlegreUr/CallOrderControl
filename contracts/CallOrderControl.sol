// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Customed Errors */
error CallOrderControl__NotAllowedCall();

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
 * @title Call Order Control.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 *
 * @notice CallOrderControl can be used to control in which order the functions from your smart contract can specific
 * addresses call them.
 *
 * @dev Check an usecase contract at UseCaseContract.sol on the github repo:
 * (add the link!)
 *
 */
contract CallOrderControl {
    /* Types */

    /**
     * @dev callSequence struct allows the user to call any func in the `funcs` array
     * but in the order they are indexed.
     *
     * `funcs` array contains the function selectors => bytes4(keccak256(bytes("funcSignatureAsString")))
     *
     * Example => First call must be done to function at index 0, then the one at index 1, then the index 2 one etc...
     */
    struct callSequence {
        bytes4[] funcs;
        uint256 callsToUse;
        uint256 currentCall;
    }

    /**
     * @dev callUnordered struct allows the user to call functions in any order but only X times each.
     */
    struct callUnordered {
        bytes4[] funcs;
        uint callsToUse;
        mapping(bytes4 => uint) funcToCallsLeft;
        mapping(bytes4 => uint) funcToPosition;
    }

    /* State Variables */

    mapping(address => bool) s_callerToIsSequence;
    mapping(address => callSequence) s_callerToFuncSequence;
    mapping(address => callUnordered) s_callerToFuncUnordered;

    /* Events */

    event CallOrderControl__AllowedFuncCallsGranted(
        address indexed caller,
        bytes4[] validFuncCalls,
        bool isSequence
    );

    /* Modifiers */

    /**
     * @dev Checks if `_callerAddress` can call `_funcSelec`.
     * If needed this modifier automatically takes charge of reseting variables' values
     * or the whole data structure of callSequence or callUnordered for `_callerAddress`
     * at `_funcSelec`.
     */
    modifier isAllowedCall(bytes4 _funcSelec, address _callerAddress) {
        if (s_callerToIsSequence[_callerAddress] == true) {
            if (s_callerToFuncSequence[_callerAddress].callsToUse == 0) {
                revert CallOrderControl__NotAllowedCall();
            }
            if (
                s_callerToFuncSequence[_callerAddress].funcs[
                    s_callerToFuncSequence[_callerAddress].currentCall
                ] != _funcSelec
            ) {
                revert CallOrderControl__NotAllowedCall();
            }

            s_callerToFuncSequence[_callerAddress].currentCall += 1;

            s_callerToFuncSequence[_callerAddress].callsToUse -= 1;

            if (s_callerToFuncSequence[_callerAddress].callsToUse == 0) {
                delete s_callerToFuncSequence[_callerAddress];
            } else {
                delete s_callerToFuncSequence[_callerAddress].funcs[
                    s_callerToFuncSequence[_callerAddress].currentCall - 1
                ];
            }
        } else {
            if (
                s_callerToFuncUnordered[_callerAddress].funcToCallsLeft[
                    _funcSelec
                ] == 0
            ) {
                revert CallOrderControl__NotAllowedCall();
            }

            s_callerToFuncUnordered[_callerAddress].funcToCallsLeft[
                _funcSelec
            ] -= 1;
            s_callerToFuncUnordered[_callerAddress].callsToUse -= 1;

            if (s_callerToFuncUnordered[_callerAddress].callsToUse != 0) {
                delete s_callerToFuncUnordered[_callerAddress].funcs[
                    s_callerToFuncUnordered[_callerAddress].funcToPosition[
                        _funcSelec
                    ] - 1
                ];
            } else {
                delete s_callerToFuncUnordered[_callerAddress];
            }
        }
        _;
    }

    /* Functions */

    /* Public functions */
    /* Getters */

    /**
     * @return Allowed funcs to be called by `_address`. If `_isSequence` == true
     * the indexes of the `funcs` array show in which order `_address` must call the functions.
     *
     * If `_isSequence` == false then functions represented in the array can be called in any
     * order.
     *
     * If any of the values is the 0 value it means the value has been used. Or in a very unlikely
     * scenario maybe the function selector is equal to the 0 value, if this is the case the 'off-chain'
     * user should have into account that one of the 0 values in the array won't necessarily mean the
     * function call has been done.
     */
    function getAllowedFuncCalls(
        address _address,
        bool _isSequence
    ) public view returns (bytes4[] memory) {
        if (_isSequence) {
            return s_callerToFuncSequence[_address].funcs;
        } else {
            return s_callerToFuncUnordered[_address].funcs;
        }
    }

    /* Internal functions */

    /**
     * @dev Override this function in your contract to use
     * allowFuncCallsFor() mixed with other useful contracts and
     * modifiers like Ownable and AccessControl contracts from
     * OpenZeppelin.
     *
     * See param specifications in allowfuncCallsFor() docs.
     */
    function callAllowFuncCallsFor(
        address _callerAddress,
        bytes4[] calldata _validFuncCalls,
        bool _isSequence
    ) public virtual {
        allowFuncCallsFor(_callerAddress, _validFuncCalls, _isSequence);
    }

    /**
     * @dev Allows `_callerAddress` to call functions represented inside `_validFuncCalls`.
     *
     * @param _validFuncCalls Each element is a function selector:
     *
     *                  bytes4(keccak256(bytes("funcSignatureAsString")))
     * 
     *Example with this function itslef:

     *      allowfuncCallsFor() function => funcSignature = "allowfuncCallsFor(address,bytes4[],string)"
     *
     * @dev Maybe a function has a function selector == the empty value for bytes4 in solidity.
     * 'Off-chain-users' should have this into account if checking what function calls they are
     *  allowed.
     *
     * @param _isSequence is a boolean. If `_isSequence` == true => You are saving allowed funcsToCall
     * in a sequence that must be followed when calling the functions. 
     * If == false: you are saving allowed calls that will be able to be called in any order.
     */
    function allowFuncCallsFor(
        address _callerAddress,
        bytes4[] calldata _validFuncCalls,
        bool _isSequence
    ) internal {
        s_callerToIsSequence[_callerAddress] = _isSequence;

        if (_isSequence) {
            s_callerToFuncSequence[_callerAddress].callsToUse = _validFuncCalls
                .length;
            s_callerToFuncSequence[_callerAddress].currentCall = 0;
            s_callerToFuncSequence[_callerAddress].funcs = _validFuncCalls;
        } else {
            s_callerToFuncUnordered[_callerAddress].callsToUse = _validFuncCalls
                .length;
            s_callerToFuncUnordered[_callerAddress].funcs = _validFuncCalls;
            for (uint256 i = 0; i < _validFuncCalls.length; i++) {
                s_callerToFuncUnordered[_callerAddress].funcToPosition[
                    _validFuncCalls[i]
                ] = i + 1;
                s_callerToFuncUnordered[_callerAddress].funcToCallsLeft[
                    _validFuncCalls[i]
                ] += 1;
            }
        }

        emit CallOrderControl__AllowedFuncCallsGranted(
            _callerAddress,
            _validFuncCalls,
            _isSequence
        );
    }
}
