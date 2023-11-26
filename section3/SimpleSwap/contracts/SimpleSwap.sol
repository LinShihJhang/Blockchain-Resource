// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    using SafeMath for uint256;
    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public _tokenA;
    address public _tokenB;

    uint256 private _reserveA; // uses single storage slot, accessible via getReserves
    uint256 private _reserveB; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address tokenA_, address tokenB_) ERC20("LPToken", "LPT") {
        require(tokenA_ != tokenB_, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        require(isContract(tokenA_), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(isContract(tokenB_), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");

        factory = msg.sender;
        (address tokenA, address tokenB) = tokenA_ < tokenB_ ? (tokenA_, tokenB_) : (tokenB_, tokenA_);
        _tokenA = tokenA;
        _tokenB = tokenB;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.
        return account.code.length > 0;
    }

    /// @notice Swap tokenIn for tokenOut with amountIn
    /// @param tokenIn The address of the token to swap from
    /// @param tokenOut The address of the token to swap to
    /// @param amountIn The amount of tokenIn to swap
    /// @return amountOut The amount of tokenOut received
    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require(tokenIn == _tokenA || tokenIn == _tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut == _tokenA || tokenOut == _tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        uint256 reserveA = _reserveA;
        uint256 reserveB = _reserveB;
        uint256 reserveIn;
        uint256 reserveOut;


        if (tokenIn == _tokenA) {
            reserveIn = reserveA;
            reserveOut = reserveB;

            amountOut = amountIn.mul(reserveOut) / reserveIn.add(amountIn);

            _reserveA += amountIn;
            _reserveB -= amountOut;

            IERC20(_tokenA).transferFrom(msg.sender, address(this), amountIn);
            IERC20(_tokenB).transfer(msg.sender, amountOut);
        } else {
            reserveIn = reserveB;
            reserveOut = reserveA;

            amountOut = amountIn.mul(reserveOut) / reserveIn.add(amountIn);

            _reserveA -= amountOut;
            _reserveB += amountIn;

            IERC20(_tokenA).transfer(msg.sender, amountOut);
            IERC20(_tokenB).transferFrom(msg.sender, address(this), amountIn);
        }

        require(reserveIn.add(amountIn).mul(reserveOut.sub(amountOut)) >= reserveIn.mul(reserveOut), "SimpleSwap: K");

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @notice Add liquidity to the pool
    /// @param amountAIn The amount of tokenA to add
    /// @param amountBIn The amount of tokenB to add
    /// @return amountA The actually amount of tokenA added
    /// @return amountB The actually amount of tokenB added
    /// @return liquidity The amount of liquidity minted
    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(amountAIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(amountBIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        if (_reserveA == 0 && _reserveB == 0) {
            (amountA, amountB) = (amountAIn, amountBIn);
        } else {
            uint256 amountBOptimal = amountAIn.mul(_reserveB) / _reserveA;
            if (amountBOptimal <= amountBIn) {
                (amountA, amountB) = (amountAIn, amountBOptimal);
            } else {
                uint256 amountAOptimal = amountBIn.mul(_reserveA)  / _reserveB;
                require(amountAOptimal <= amountAIn, "SimpleSwap: Add Liquidity ERROR");
                (amountA, amountB) = (amountAOptimal, amountBIn);
            }
        }

        // if (totalSupply == 0) {
        //     // liquidity = Math.sqrt(amountA.mul(amountB)).sub(MINIMUM_LIQUIDITY);
        //     // _mint(address(this), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        //     // _burn(address(this), MINIMUM_LIQUIDITY);
        //     liquidity = Math.sqrt(amountA.mul(amountB));
        // } else {
        //     liquidity = Math.min(amountA.mul(totalSupply) / _reserveA, amountB.mul(totalSupply) / _reserveB);
        // }
        liquidity = Math.sqrt(amountA.mul(amountB));
        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_MINTED");

        IERC20(_tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), amountB);
        _mint(msg.sender, liquidity);
        _reserveA += amountA;
        _reserveB += amountB;
        emit AddLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Remove liquidity from the pool
    /// @param liquidity The amount of liquidity to remove
    /// @return amountA The amount of tokenA received
    /// @return amountB The amount of tokenB received
    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {
        _transfer(msg.sender, address(this), liquidity);

        address tokenA = _tokenA; // gas savings
        address tokenB = _tokenB; // gas savings
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        // uint256 liquidity = balanceOf[address(this)];
        uint256 totalSupply = totalSupply();
        amountA = liquidity.mul(balanceA) / totalSupply;
        amountB = liquidity.mul(balanceB) / totalSupply;
        require(amountA > 0 && amountB > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");

        _burn(address(this), liquidity);

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        balanceA = IERC20(tokenA).balanceOf(address(this));
        balanceB = IERC20(tokenB).balanceOf(address(this));

        _reserveA = balanceA;
        _reserveB = balanceB;

        emit RemoveLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Get the reserves of the pool
    /// @return reserveA The reserve of tokenA
    /// @return reserveB The reserve of tokenB
    function getReserves() external view returns (uint256 reserveA, uint256 reserveB) {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    /// @notice Get the address of tokenA
    /// @return tokenA The address of tokenA
    function getTokenA() external view returns (address tokenA) {
        return _tokenA;
    }

    /// @notice Get the address of tokenB
    /// @return tokenB The address of tokenB
    function getTokenB() external view returns (address tokenB) {
        return _tokenB;
    }
}
