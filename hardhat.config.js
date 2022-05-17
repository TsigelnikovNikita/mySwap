require("@nomiclabs/hardhat-waffle");
require('hardhat-dependency-compiler');

module.exports = {
  solidity: "0.8.4",
  dependencyCompiler: {
    paths: [
      "@openzeppelin/contracts/token/ERC20/IERC20.sol",
      "@openzeppelin/contracts/token/ERC20/ERC20.sol",
      "@openzeppelin/contracts/access/Ownable.sol",
    ]
  }
};
