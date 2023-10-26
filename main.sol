//SPDX-License-Identifier: GPL-3.0 
pragma solidity ^0.8.0; 

contract EnsDomain {

  address owner;
  uint public priceDomainPerYear;
  uint public priceDomainPerYearExtension;
  uint constant yearToTimestamp = 31536000; // 1 year = 31.536.000 timestamp
  mapping (string => WalletInfo) public domainsList;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "You are now an owner");
    _;
  }

  modifier checkPeriod(uint8 period) {
      require(1 <= period && period <= 10, "Registration time only from 1 to 10 years"); // проверяем срок регистрации
    _;
  }

  struct WalletInfo {
    address owner;
    uint256 timestamp;
    uint256 price;
    uint256 deadlineDomain;
  }

  function getDomainPrice(uint8 period) public view returns (uint) {
    return priceDomainPerYear * period;
  }

  function getDomainPriceExtension(uint8 period) public view returns (uint) {
    return priceDomainPerYearExtension * period;
  }

  function getDomainOwner(string memory domainName) public view returns (address) { 
    return domainsList[domainName].owner;
  }

  function setDomainPrice(uint price) public onlyOwner {
    priceDomainPerYear = price;
  }

  function setDomainExtensionPrice(uint price) public onlyOwner {
    priceDomainPerYearExtension = price;
  }

  function withdrawAll(address payable wallet) public onlyOwner {
    wallet.transfer(address(this).balance);
  }

  function addWallet(string memory domainName, uint deadline) private {
    domainsList[domainName] = WalletInfo({
      owner: msg.sender,
      timestamp: block.timestamp,
      price: msg.value,
      deadlineDomain: deadline
    });
  }

  function registationDomain(string memory domainName, uint8 period) public payable checkPeriod(period) {
    require(msg.value >= getDomainPrice(period), "Value is not enough"); // проверяем достаточно ли value
    require(domainsList[domainName].deadlineDomain <= block.timestamp, // смотрим не истек ли срок его действия
      "Domain is unavaiable"
    );
    // нижняя проверка не нужна, тк если домена не существует, его deadlineDomain будет = 0
    // require(
    //   domainsList[domainName].owner == 0x0000000000000000000000000000000000000000, // проверяем сущетсвует ли такой домен
    //   "Domain is unavaiable"
    // );

    addWallet(domainName, block.timestamp + period * yearToTimestamp);
  }

  function domainExtension(string memory domainName, uint8 period) public payable checkPeriod(period) {
    require(domainsList[domainName].owner == msg.sender, "You are now an owner");
    require(msg.value >= priceDomainPerYearExtension * period, "Value is not enough"); // проверяем достаточно ли value

    uint _deadlineDomain = domainsList[domainName].deadlineDomain + period * yearToTimestamp;
    // общий срок домена должен быть от 1 до 10 лет
    require(
      block.timestamp + yearToTimestamp < _deadlineDomain 
      && 
      _deadlineDomain < block.timestamp + yearToTimestamp * 10, 
      "Domain time only from 1 to 10 years"
    );

    addWallet(domainName, _deadlineDomain);
  }
}
