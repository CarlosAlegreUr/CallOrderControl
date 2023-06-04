<hr/>
<hr/>

<a name="readme-top"></a>

# [Call Order Control Contract](https://github.com/CarlosAlegreUr/CallOrderControl-SmartContract-DesignPattern)

<hr/>

# Tests and simple implementation for CallOrderControl contract.

Check the contract code here => [(click)](https://github.com/CarlosAlegreUr/CallOrderControl-SmartContract-DesignPattern)

Check the npm repository => [(click)](https://www.npmjs.com/package/input-control-contract)

If further elaboration, development or testing please mention me in your work.

😉 https://github.com/CarlosAlegreUr 😉

<hr/>

## 📰 Last Changes 📰

- Fixed bug, funcToCallsLeft mapping now is overwritten correctly. In previous version it could overflow and/or lead to unexpected behaviours.

- Added getIsSequence() function.
- Deleted argument \_isSequence ins getAllowedFuncCalls().
- New tests for funcToCallsLeft unexpected behaviour added.
- New test for function getIsSequience() added.

## 🎉 FUTURE IMPROVEMENTS 🎉

- Improve and review (static analysis, audit...) code's tests.

- Test in testnet.
- Check if worth it to create better option: adding more allowed calls to client who hasn't used all of them. Now it overwrites.
- Check gas implications of changing 4 bytes function selector to 32 bytes hashed function signatures.

## 📨 Contact 📨

Carlos Alegre Urquizú - calegreu@gmail.com

<hr/>

## ☕ Buy me a CryptoCoffee ☕

Buy me a crypto coffe in ETH, MATIC or BNB ☕🧐☕
(or tokens if you please :p )

0x2365bf29236757bcfD141Fdb5C9318183716d866

<hr/>

## 📜 License 📜

Distributed under the MIT License. See [LICENSE](https://github.com/CarlosAlegreUr/CallOrderControl-SmartContract-DesignPattern/blob/main/LICENSE) in the repository for more information.

([back to top](#🙀-the-problem-🙀))

<hr/>
<hr/>
