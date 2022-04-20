// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BonusToken is ERC20 {
  address public admin;
  address public liquidator;
  constructor() ERC20('Bonus Token', 'BTK') public {
    admin = msg.sender;
  }

  function setLiquidator(address _liquidator) external {
    require(admin == msg.sender, 'only admin');
    liquidator = _liquidator;
  }

  function mint(address _to, uint _amount) {
    require(liquidator == msg.sender, 'only liquidator');
    _mint(_to, _amount);
  }
}
