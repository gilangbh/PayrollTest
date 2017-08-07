pragma solidity  ^0.4.10;

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed. Standard base level contract
///
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

// For the sake of simplicity lets asume USD is a ERC20 token
// Also lets asume we can 100% trust the exchange rate oracle
contract PayrollInterface {
  /* OWNER ONLY */
  function addEmployee(address accountAddress, address[] allowedTokens, uint256 initialYearlyUSDSalary);
  function setEmployeeSalary(uint256 employeeId, uint256 yearlyUSDSalary);
  function removeEmployee(uint256 employeeId);

  function addFunds() payable;
  function scapeHatch();
  // function addTokenFunds()? // Use approveAndCall or ERC223 tokenFallback

  function getEmployeeCount() constant returns (uint256);
  function getEmployee(uint256 employeeId) constant returns (address employee); // Return all important info too

  function calculatePayrollBurnrate() constant returns (uint256); // Monthly usd amount spent in salaries
  function calculatePayrollRunway() constant returns (uint256); // Days until the contract can run out of funds

  /* EMPLOYEE ONLY */
  function determineAllocation(address[] tokens, uint256[] distribution); // only callable once every 6 months
  function payday(); // only callable once a month

  /* ORACLE ONLY */
  function setExchangeRate(address token, uint256 usdExchangeRate); // uses decimals from token
}

contract Payroll is PayrollInterface, Owned {
    using SafeMath for uint256;

    uint256 constant public totalMonthsInaYear = 12;

    mapping(address => uint256) employeeIds;
    uint256 employeeCount;
    uint256 totalPayrollYearly;

    struct Employee {
        address employeeAddress;
        address[] allowedTokens;
        uint256 initialYearlyUSDSalary;
    }


    Employee[] employees;
    Employee employee;

    modifier onlyEmployee() {
        require(employeeIds[msg.sender] > 0);
        _;
    }

    function Payroll() onlyOwner{
        Employee initialEmployee = employee;
        initialEmployee.employeeAddress = 0x0;
        initialEmployee.allowedTokens.push(0x0);
        initialEmployee.initialYearlyUSDSalary = 0;
        employees.push(initialEmployee);
        employeeCount = 0;
        totalPayrollYearly = 0;
    }

    function addEmployee(address accountAddress, address[] allowedTokens, uint256 initialYearlyUSDSalary) onlyOwner{
        if(employeeIds[accountAddress] == 0) return;
        if(employeeIds[accountAddress] > 0) return;
        Employee addedEmployee = employee;
        addedEmployee.employeeAddress = accountAddress;
        addedEmployee.allowedTokens = allowedTokens;
        addedEmployee.initialYearlyUSDSalary = initialYearlyUSDSalary;

        employees.push(addedEmployee);
        employeeIds[accountAddress] = employees.length;
        employeeCount += 1;

        totalPayrollYearly += initialYearlyUSDSalary;
    }

    function setEmployeeSalary(uint256 employeeId,uint256 yearlyUSDSalary) onlyOwner{
        totalPayrollYearly -= employees[employeeId].initialYearlyUSDSalary;
        totalPayrollYearly += yearlyUSDSalary;
        employees[employeeId].initialYearlyUSDSalary = yearlyUSDSalary;
    }

    function removeEmployee(uint256 employeeId) onlyOwner{
        totalPayrollYearly -= employees[employeeId].initialYearlyUSDSalary;
        employeeIds[employees[employeeId].employeeAddress] = 0;
        delete employees[employeeId];
        
        employeeCount -= 1;
    }

    function addFunds() payable {

    }

    function getEmployeeCount() constant returns (uint256){
        return employeeCount;
    }

    function getEmployee(uint employeeId) constant returns (address employee){
        
    }

    function calculatePayrollBurnrate() constant returns (uint256){
        uint256 monthlyPayrollBurnRate = SafeMath.div(totalPayrollYearly,totalMonthsInaYear);
        return monthlyPayrollBurnRate;
    }

    function calculatePayrollRunway() constant returns (uint256){
        uint256 monthlyPayrollBurnRate = calculatePayrollBurnrate();
        uint256 totalMonthLeft = SafeMath.div(this.balance,monthlyPayrollBurnRate);
    }

    function determineAllocation(address[] tokens, uint256[] distribution) onlyEmployee{

    }

    function payday() onlyEmployee{

    }
}