# SafeERC20

SafeERC20 is a library that provide helper functions to mitigate the most commons or obvious risks when using ERC20s. These risks are:
- Not all contracts return a boolean value on success or fail of `transfer`, `transferFrom` and `approve`, some contracts revert with error. To handle all cases SafeERC20 provides `safeTransfer`, `safeTransferFrom` and `saveApprove` functions;
- Design of the standard `approve` function opens a gate for front-running (that never happened so far though https://twitter.com/bantg/status/1699765906887327874) - this issue can be partly addressed by using SafeERC20's `safeIncreaseAllowance` and `safeDecreaseAllowance` functions
