pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "./IPool.sol";
import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {IFlashLoanSimpleReceiver} from "./IFlashLoanSimpleReceiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "compound-protocol/contracts/CErc20.sol";
import "compound-protocol/contracts/CTokenInterfaces.sol";

contract AaveFlashLoan is IFlashLoanSimpleReceiver {
    struct CallbackData {
        address USDC;
        address UNI;
        address cUSDC;
        address cUNI;
        address borrower;
        uint256 liquidateAmount;
        address liquidator;
    }

    //address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant POOL_ADDRESSES_PROVIDER =
        0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;

    function execute(bytes calldata callbackData) external {
        CallbackData memory data = abi.decode(callbackData, (CallbackData));
        POOL().flashLoanSimple(
            address(this),
            data.USDC,
            data.liquidateAmount,
            callbackData,
            0
        );
        IERC20(data.USDC).transfer(
            data.liquidator,
            IERC20(data.USDC).balanceOf(address(this))
        );
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        CallbackData memory data = abi.decode(params, (CallbackData));

        CErc20 cUSDC = CErc20(data.cUSDC);
        CErc20 cUNI = CErc20(data.cUNI);
        IERC20 USDC = IERC20(data.USDC);
        IERC20 UNI = IERC20(data.UNI);

        USDC.approve(data.cUSDC, amount * 10);
        uint success = cUSDC.liquidateBorrow(
            data.borrower,
            amount,
            CTokenInterface(data.cUNI)
        );
        require(success == 0, "liquidateBorrow faild");

        UNI.approve(data.cUNI, amount);
        cUNI.redeem(cUNI.balanceOf(address(this)));
        uint UNIbalance = UNI.balanceOf(address(this));
        require(UNIbalance > 0, "redeem faild");

        // https://docs.uniswap.org/protocol/guides/swaps/single-swaps
        ISwapRouter swapRouter = ISwapRouter(
            0xE592427A0AEce92De3Edee1F18E0157C05861564
        );
        UNI.approve(address(swapRouter), UNIbalance);
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: data.UNI,
                tokenOut: data.USDC,
                fee: 3000, // 0.3%
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: UNIbalance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = swapRouter.exactInputSingle(swapParams);

        USDC.approve(address(POOL()), amountOut);

        return true;
    }

    function ADDRESSES_PROVIDER() public view returns (IPoolAddressesProvider) {
        return IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
    }

    function POOL() public view returns (IPool) {
        return IPool(ADDRESSES_PROVIDER().getPool());
    }
}
