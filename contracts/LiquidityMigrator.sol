// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./BonusToken.sol";


contract LiquidityMigrator {
  IUniswapV2Router02 public router;
  IUniswapV2Pair public pair;
  IUniswapV2Router02 public routerForked;
  IUniswapV2Pair public pairForked;
  BonusToken public bonusToken;
  address public admin;
  mapping (address => uint) public unclaimedBalances;
  bool public migrationDone;

  constructor(address _router, address _pair, address _routerForked, address _pairForked, address _bonuskToken) public {
    router = IUniswapV2Router02(_router);
    pair = IUniswapV2Pair(_pair);
    routerForked = IUniswapV2Router02(_routerForked);
    pairForked = IUniswapV2Pair(_pairForked);
    bonusToken = BonusToken(_bonuskToken);
    admin = msg.sender;
  }

  function deposit(uint _amount) external {
    require(migrationDone == false, 'migration already done');
    pair.transferFrom(msg.sender, address(this), _amount);
    bonusToken.mint(msg.sender, _amount);
    unclaimedBalances[msg.sender] += _amount;
  }

  function migrate() external {
    require(admin == msg.sender, 'only admin');
    require(migrationDone == false, 'migration already done');

    /* get the pointers of the tokens involved in token pair */
    IERC20 token0 = IERC20(pair.token0());
    IERC20 token1 = IERC20(pair.token1());

    /* get the total liquidity balance accumulated for our token */
    uint totalBalance = pair.totalSupply();

    /* remove liquidity from the uniswap */
    router.removeLiquidity(address(token0), address(token1), totalBalance, 0, 0, address(this), block.timestamp);

    /* balance of this contract in the tokens received from uniswap */
    uint token0Balance = token0.balanceOf(address(this));
    uint token1Balance = token1.balanceOf(address(this));

    /* allow new router to spend tokens */
    token0.approve(address(routerForked), token0Balance);
    token1.approve(address(routerForked), token0Balance);

    /* add liquidity to forked uniswap */
    routerForked.addLiquidity(address(token0), address(token1), token0Balance, token1Balance, token0Balance, token1Balance, address(this), block.timestamp);
    migrationDone = true;
  }

  function claimBonusTokens() external {
    require(unclaimedBalances[msg.sender] >= 0, 'no unclaimed tokens');
    require(migrationDone == true, 'migration not done yet');
    uint amount = unclaimedBalances[msg.sender];
    unclaimedBalances[msg.sender] = 0;
    pairForked.transfer(msg.sender, amount);
  }
}
