pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "./IPool.sol";
import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {IFlashLoanSimpleReceiver} from "./IFlashLoanSimpleReceiver.sol";

//import {IFlashLoanSimpleReceiver, IPoolAddressesProvider, IPool} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";

contract AaveFlashLoan is IFlashLoanSimpleReceiver {
    struct CallbackData {
        address USDC;
        address cUSDC;
        address cUNI;
        address UNI;
        uint256 borrower;
        uint256 borrowBalance;
        address liquidator;
        address borrower;
    }

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant POOL_ADDRESSES_PROVIDER =
        0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;

    function execute(CallbackData data) external {
        //IERC20(USDC).approve(address(POOL()), 110_000_000 * 10 ** 6);
        // POOL().flashLoanSimple(
        //     address(this),
        //     USDC,
        //     10_000_000 * 10 ** 6,
        //     abi.encode(address(checker)),
        //     0
        // );
        // // https://docs.uniswap.org/protocol/guides/swaps/single-swaps
        // ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
        //     .ExactInputSingleParams({
        //         tokenIn: UNI_ADDRESS,
        //         tokenOut: USDC_ADDRESS,
        //         fee: 3000, // 0.3%
        //         recipient: address(this),
        //         deadline: block.timestamp,
        //         amountIn: uniAmount,
        //         amountOutMinimum: 0,
        //         sqrtPriceLimitX96: 0
        //     });
        // // The call to `exactInputSingle` executes the swap.
        // // swap Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564
        // uint256 amountOut = swapRouter.exactInputSingle(swapParams);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        // (address checkerAddress) = abi.decode(params, (address));
        // BalanceChecker(checkerAddress).checkBalance();
        return true;
    }

    function ADDRESSES_PROVIDER() public view returns (IPoolAddressesProvider) {
        return IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
    }

    function POOL() public view returns (IPool) {
        return IPool(ADDRESSES_PROVIDER().getPool());
    }
}
