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


contract Payroll is PayrollInterface {
        
    struct Employee {
        address employeeAddress;
        address[] allowedTokens;
        uint256 initialYearlyUSDSalary;
    }

    mapping(address => uint) employeeIds;

    Employee[] employees;

    modifier onlyEmployee() {

    }

    function addEmployee(address accountAddress, address[] allowedTokens, uint256 initialYearlyUSDSalary) onlyOwner{
        var employee = Employee(accountAddress,allowedTokens,initialYearlyUSDSalary);
        employees.push(employee);
        employeeIds[accountAddress] = employees.length;
    }

    function setEmployeeSalary(uint256 employeeId,uint256 yearlyUSDSalary) onlyOwner{
        employees[employeeId].initialYearlyUSDSalary = yearlyUSDSalary;
    }

    function removeEmployee(uint256 employeeId) onlyOwner{
        delete employees[employeeId];
    }

    function addFunds() payable {

    }
}