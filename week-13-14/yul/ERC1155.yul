object "ERC1155" {
  code {
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
        mstore(0x40, 0x80)
        require(iszero(callvalue()))

        switch selector()
        case 0x00fdd58e {
          balanceOf()
        }
        case 0x4e1273f4 {
          balanceOfBatch()
        }
        case 0xe985e9c5 {
          isApprovedForAll()
        }
        case 0xa22cb465 {
          setApprovalForAll()
        }
        case 0xf242432a {
          safeTransferFrom()
        }
        case 0x731133e9 {
          mint()
        }
        case 0xb48ab8b6 {
          batchMint()
        }
        case 0xf5298aca {
          burn()
        }
        case 0xf6eb127a {
          batchBurn()
        }
        case 0x2eb2c2d6 {
          safeBatchTransferFrom()
        }
        default {
          revert(0, 0)
        }

        /** view functions */
        function balanceOf(/* address account, uint256 id */) {
          let slot := getBalanceSlot(calldataload(0x24), calldataload(0x04))
          let ptr := mload(0x40)
          mstore(ptr, sload(slot))
          return(ptr, 0x20)
        }

        function balanceOfBatch(/* address[] memory accounts, uint256[] memory ids */) {
          let accountsOffset := add(calldataload(0x04), 0x04)
          let idsOffset := add(calldataload(0x24), 0x04)
          let accountLength := calldataload(accountsOffset)
          let idsLength := calldataload(idsOffset)
          if iszero(eq(accountLength, idsLength)) {
            revertInvalidArrayLength(idsLength, accountLength)
          }

          let memptr    := mload(0x40)
          mstore(memptr, 0x20)
          let freeptr   := add(memptr, 0x20)
          mstore(freeptr, idsLength)
          freeptr       := add(freeptr, 0x20)
          mstore(0x40, freeptr)
          for { let i := 0 } lt(i, idsLength) { /* empty */ } {
            i                 := add(i, 1)
            let accountOffset := add(accountsOffset, mul(i, 0x20))
            let idOffset      := add(idsOffset, mul(i, 0x20))
            let account       := calldataload(accountOffset)
            let id            := calldataload(idOffset)
            mstore(
              freeptr,
              sload(getBalanceSlot(id, account))
            )
            freeptr := add(freeptr, 0x20)
            mstore(0x40, freeptr)
          }
          return(memptr, sub(freeptr, memptr))
        }

        function isApprovedForAll(/* address account, address operator */) {
          let account   := calldataload(0x04)
          let operator  := calldataload(0x24)
          let ptr := mload(0x40)
          mstore(ptr, sload(getOperatorApprovalsSlot(account, operator)))
          return(ptr, 0x20)
        }

        /** public write functions */
        function setApprovalForAll(/* address operator, bool approved */) {
          let operator  := calldataload(0x04)
          let approved  := calldataload(0x24)
          _setApprovalForAll(caller(), operator, approved)
        }

        function safeTransferFrom(/* from, to, id, value, callbackdata */) {
          let from          := calldataload(0x04)
          let to            := calldataload(0x24)
          let id            := calldataload(0x44)
          let value         := calldataload(0x64)
          let sender        := caller()
          if iszero(eq(from, sender)) {
            let approved := sload(getOperatorApprovalsSlot(from, sender))
            if iszero(approved) {
              revertMissingApprovalForAll(sender, from)
            }
          }
          _safeTransferFrom(from, to, id, value, 0x84)
        }

        function safeBatchTransferFrom(/* address from, address to, uint256[] ids, uint256[] amounts, bytes data */) {
          let from          := calldataload(0x04)
          let to            := calldataload(0x24)
          let sender        := caller()
          if iszero(eq(from, sender)) {
            let approved := sload(getOperatorApprovalsSlot(from, sender))
            if iszero(approved) {
              revertMissingApprovalForAll(sender, from)
            }
          }
          _safeBatchTransferFrom(from, to, 0x44, 0x64, 0x84)
        }

        function mint(/* address to, uint256 id, uint256 amount, bytes memory data */) {
          let to            := calldataload(0x04)
          let id            := calldataload(0x24)
          let amount        := calldataload(0x44)
          _mint(to, id, amount, 0x64)
        }

        function batchMint(/* address to, uint256 ids, uint256 amounts, bytes memory data */) {
          let to            := calldataload(0x04)
          _mintBatch(to, 0x24, 0x44, 0x64)
        }

        function burn(/* address from, uint256 id, uint256 amount */) {
          let from          := calldataload(0x04)
          let id            := calldataload(0x24)
          let amount        := calldataload(0x44)
          _burn(from, id, amount)
        }

        function batchBurn(/* address from, uint256[] memory ids, uint256[] memory amounts */) {
          let from          := calldataload(0x04)
          _burnBatch(from, 0x24, 0x44)
        }

        /** private write functions */
        function _safeTransferFrom(from, to, id, value, callbackdata) {
          if eq(to, 0x0) {
            revertInvalidReceiver(0x0)
          }
          if eq(from, 0x0) {
            revertInvalidSender(0x0)
          }
          _updateWithAcceptanceCheck(from, to, id, value, callbackdata)
          emitTransferSingle(caller(), from, to, id, value)
        }

        function _safeBatchTransferFrom(from, to, ids, values, callbackdata) {
          if eq(to, 0x0) {
            revertInvalidReceiver(0x0)
          }
          if eq(from, 0x0) {
            revertInvalidSender(0x0)
          }
          _updateWithAcceptanceCheckBatch(from, to, ids, values, callbackdata)
          emitTransferBatch(caller(), from, to, ids, values)
        }

        function _mint(to, id, value, callbackdata) {
          if eq(to, 0x0) {
            revertInvalidReceiver(0x0)
          }
          _updateWithAcceptanceCheck(0x0, to, id, value, callbackdata)
          emitTransferSingle(caller(), 0x0, to, id, value)
        }

        function _mintBatch(to, ids, values, callbackdata) {
          if eq(to, 0x0) {
            revertInvalidReceiver(0x0)
          }
          _updateWithAcceptanceCheckBatch(0x0, to, ids, values, callbackdata)
          emitTransferBatch(caller(), 0x0, to, ids, values)
        }

        function _burn(from, id, value) {
          if eq(from, 0x0) {
            revertInvalidSender(0x0)
          }
          _updateWithAcceptanceCheck(from, 0x0, id, value, 0x0)
          emitTransferSingle(caller(), from, 0x0, id, value)
        }

        function _burnBatch(from, ids, values) {
          if eq(from, 0x0) {
            revertInvalidSender(0x0)
          }
          _updateWithAcceptanceCheckBatch(from, 0x0, ids, values, 0x0)
          emitTransferBatch(caller(), from, 0x0, ids, values)
        }

        function _setApprovalForAll(owner, operator, approved) {
          let slot := getOperatorApprovalsSlot(owner, operator)
          sstore(slot, approved)
          emitApprovalForAll(owner, operator, approved)
        }

        function _update(from, to, id, value, emit) {
          if iszero(eq(from, 0x0)) {
            let fromBalanceSlot := getBalanceSlot(id, from)
            let fromBalance     := sload(fromBalanceSlot)
            if lt(fromBalance, value) {
              revertInsufficientBalance(from, fromBalance, value, id)
            }
            sstore(fromBalanceSlot, sub(fromBalance, value))
          }

          if iszero(eq(to, 0x0)) {
            let toBalanceSlot := getBalanceSlot(id, to)
            let toBalance     := sload(toBalanceSlot)
            sstore(toBalanceSlot, add(toBalance, value))
          }

          if emit {
            emitTransferSingle(caller(), from, to, id, value)
          }
        }

        function _updateBatch(from, to, ids, values) {
          let idsOffset    := add(calldataload(ids), 0x04)
          let valuesOffset := add(calldataload(values), 0x04)
          let idsLength    := calldataload(idsOffset)
          let valuesLength := calldataload(valuesOffset)
          if iszero(eq(idsLength, valuesLength)) {
            revertInvalidArrayLength(idsLength, valuesLength)
          }

          let operator := caller()
          for { let i := 0 } lt(i, idsLength) { } {
            i := add(i, 1)
            let id    := calldataload(add(idsOffset, mul(0x20, i)))
            let value := calldataload(add(valuesOffset, mul(0x20, i)))
            _update(from, to, id, value, false)
          }

          // TODO: emitTransferBatch(operator, from, to, ids, values)
        }

        function _updateWithAcceptanceCheck(from, to, id, value, callbackdata) {
          _update(from, to, id, value, true)
          if gt(extcodesize(to), 0) { // if to != 0x0 and to.code.length > 0
            let onERC1155ReceivedSelector := 0xf23a6e6100000000000000000000000000000000000000000000000000000000
            let ptr := mload(0x40) // free memory pointer
            mstore(ptr, onERC1155ReceivedSelector)
            mstore(add(ptr, 0x04), caller())
            mstore(add(ptr, 0x24), from)
            mstore(add(ptr, 0x44), id)
            mstore(add(ptr, 0x64), value)
            mstore(add(ptr, 0x84), 0xa0) // dataOffset
            let nextPtr := _copyBytesToMemory(add(ptr, 0xa4), callbackdata)
            mstore(0x40, nextPtr)
            let ret := call(gas(), to, 0, ptr, sub(nextPtr, ptr), 0x00, 0x04)
            returndatacopy(nextPtr, 0x00, returndatasize())
            let response := mload(nextPtr)
            if iszero(ret) {
              if eq(returndatasize(), 0) {
                revertInvalidReceiver(to)
              }
              revert(nextPtr, returndatasize())
            }
            if iszero(eq(response, onERC1155ReceivedSelector)) {
              revertInvalidReceiver(to)
            }
          }
        }

        function _updateWithAcceptanceCheckBatch(from, to, ids, values, callbackdata) {
          _updateBatch(from, to, ids, values)
          if and(iszero(eq(to, 0x0)), gt(extcodesize(to), 0)) { // if to != 0x0 and to.code.length > 0
            let idsLength := calldataload(ids)
            let onERC1155BatchReceivedSelector := 0xbc197c8100000000000000000000000000000000000000000000000000000000
            let ptr := mload(0x40) // free memptr
            mstore(ptr, onERC1155BatchReceivedSelector)
            mstore(add(ptr, 0x04), caller())
            mstore(add(ptr, 0x24), from)
            mstore(add(ptr, 0x44), 0xa0) // idsOffset
            let nextPtr := _copyArrayToMemory(add(ptr, 0xa4), ids)
            mstore(add(ptr, 0x64), sub(sub(nextPtr, ptr), 4)) // valuesOffset
            nextPtr     := _copyArrayToMemory(nextPtr, values)
            mstore(add(ptr, 0x84), sub(sub(nextPtr, ptr), 4)) // callbackDataOffset
            nextPtr     := _copyBytesToMemory(nextPtr, callbackdata)
            mstore(0x40, nextPtr)
            let ret := call(gas(), to, 0, ptr, sub(nextPtr, ptr), 0x00, 0x04)
            returndatacopy(nextPtr, 0x00, returndatasize())
            let response := mload(nextPtr)
            if iszero(ret) {
              if eq(returndatasize(), 0) {
                revertInvalidReceiver(to)
              }
              revert(nextPtr, returndatasize())
            }
            if iszero(eq(response, onERC1155BatchReceivedSelector)) {
              revertInvalidReceiver(to)
            }
          }
        }

        function _copyBytesToMemory(offsetPtr, calldataBytes) -> ptr {
          if eq(calldataBytes, 0x0) {
            mstore(offsetPtr, 0x0)
            ptr := add(offsetPtr, 0x20)
            leave
          }

          let bytesOffset := add(calldataload(calldataBytes), 0x04)
          let length      := calldataload(bytesOffset)
          if eq(length, 0x0) {
            mstore(offsetPtr, 0x0)
            ptr := add(offsetPtr, 0x20)
            leave
          }
          let totalLength := add(0x20, length)
          let rem := mod(totalLength, 0x20)
          if rem {
            totalLength := add(totalLength, sub(0x20, rem))
          }
          calldatacopy(offsetPtr, bytesOffset, totalLength)
          ptr := add(offsetPtr, totalLength)
        }

        function _copyArrayToMemory(offsetPtr, arr) -> ptr {
          let arrOffset   := add(calldataload(arr), 0x04)
          let length      := calldataload(arrOffset)
          let totalLength := add(0x20, mul(0x20, length))
          calldatacopy(offsetPtr, arrOffset, totalLength)
          ptr := add(offsetPtr, totalLength)
        }


        /** storage layout */
        function balances() -> p {
          p := 0
        }
        function operatorApprovals() -> p {
          p := 1
        }

        function getBalanceSlot(id, account) -> slot {
          let ptr := mload(0x40)
          mstore(ptr, balances())
          mstore(add(0x20, ptr), id)
          mstore(ptr, keccak256(ptr, 0x40))
          mstore(add(0x20, ptr), account)
          slot := keccak256(ptr, 0x40)
          mstore(0x40, ptr)
        }

        function getOperatorApprovalsSlot(account, operator) -> slot {
          let ptr := mload(0x40)
          mstore(ptr, balances())
          mstore(add(0x20, ptr), account)
          mstore(ptr, keccak256(ptr, 0x40))
          mstore(add(0x20, ptr), operator)
          slot := keccak256(ptr, 0x40)
          mstore(0x40, ptr)
        }

        /** events */
        function emitLog(value) {
          let eventSignature := 0x32d5ab96f608074ecb7a2188938a6154ca0cb72029f98b277aa9284b9d47f5c3
          let ptr := mload(0x40)
          mstore(ptr, value)
          mstore(0x40, ptr)
          log0(ptr, 0x20)
        }

        function emitTransferSingle(operator, from, to, id, value) {
          let eventSignature := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
          let ptr := mload(0x40)
          mstore(ptr, id)
          mstore(add(0x20, ptr), value)
          log4(ptr, 0x40, eventSignature, operator, from, to)
          mstore(0x40, ptr)
        }

        function emitTransferBatch(operator, from, to, ids, values) {
          let eventSignature := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
          let ptr := mload(0x40)
          mstore(ptr, 0x40)
          let nextPtr := _copyArrayToMemory(add(ptr, 0x40), ids)
          mstore(add(ptr, 0x20), sub(nextPtr, ptr))
          nextPtr := _copyArrayToMemory(nextPtr, values)
          log4(ptr, sub(nextPtr, ptr), eventSignature, operator, from, to)
          mstore(0x40, ptr)
        }

        function emitApprovalForAll(account, operator, approved) {
          let eventSignature := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
          let ptr := mload(0x40)
          mstore(ptr, approved)
          log3(ptr, 0x20, eventSignature, account, operator)
          mstore(0x40, ptr)
        }

        function emitURI(value, id) {
          let eventSignature := 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b
          let ptr := mload(0x40)
          mstore(ptr, value)
          log2(ptr, 0x20, eventSignature, id)
          mstore(0x40, ptr)
        }

        /** errors */
        function revertInsufficientBalance(sender, curBalance, needed, tokenId) {
          let signature := 0x03dee4c500000000000000000000000000000000000000000000000000000000
          let ptr := mload(0x40)
          mstore(ptr, signature)
          mstore(add(ptr, 0x04), sender)
          mstore(add(ptr, 0x24), curBalance)
          mstore(add(ptr, 0x44), needed)
          mstore(add(ptr, 0x64), tokenId)
          revert(ptr, 0x84)
        }

        function revertInvalidSender(sender) {
          let signature := 0x01a8351400000000000000000000000000000000000000000000000000000000
          let ptr := mload(0x40)
          mstore(ptr, signature)
          mstore(add(ptr, 0x04), sender)
          revert(ptr, 0x24)
        }

        function revertInvalidReceiver(receiver) {
          let signature := 0x57f447ce00000000000000000000000000000000000000000000000000000000
          let ptr := mload(0x40)
          mstore(ptr, signature)
          mstore(add(ptr, 0x04), receiver)
          revert(ptr, 0x24)
        }

        function revertMissingApprovalForAll(operator, owner) {
          let signature := 0xe237d92200000000000000000000000000000000000000000000000000000000
          let ptr := mload(0x40)
          mstore(ptr, signature)
          mstore(add(ptr, 0x04), operator)
          mstore(add(ptr, 0x24), owner)
          revert(ptr, 0x44)
        }

        function revertInvalidOperator(operator) {
          let signature := 0xced3e10000000000000000000000000000000000000000000000000000000000
          let ptr := mload(0x40)
          mstore(ptr, signature)
          mstore(add(ptr, 0x04), operator)
          revert(ptr, 0x24)
        }

        function revertInvalidArrayLength(idsLength, valuesLength) {
          let signature := 0x5b05999100000000000000000000000000000000000000000000000000000000
          let ptr := mload(0x40)
          mstore(ptr, signature)
          mstore(add(ptr, 0x04), idsLength)
          mstore(add(ptr, 0x24), valuesLength)
          revert(ptr, 0x44)
        }

        /** utils */
        function require(condition) {
            if iszero(condition) { revert(0, 0) }
        }

        function selector() -> s {
          s := shr(0xe0, calldataload(0))
        }

        function _asSingletonArrays(element1, element2) -> array1, array2 {
            array1 := mload(0x40)
            mstore(array1, 1)
            mstore(add(array1, 0x20), element1)

            array2 := add(array1, 0x40)
            mstore(array2, 1)
            mstore(add(array2, 0x20), element2)

            mstore(0x40, add(array2, 0x40))
        }
    }
  }
}