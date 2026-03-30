// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32 } from "@fhenixprotocol/contracts/FHE.sol";

contract PrivaraPaymentGateway {
    using FHE for euint32;

    struct Deposit {
        address user;
        uint256 timestamp;
    }

    struct Withdrawal {
        address user;
        uint256 timestamp;
        bool processed;
    }

    mapping(address => euint32) private balances;

    mapping(address => Deposit[]) public userDeposits;
    mapping(address => Withdrawal[]) public userWithdrawals;

    euint32 public totalPool;

    mapping(address => bool) public authorizedContracts;

    event Deposited(address indexed user);
    event WithdrawalRequested(address indexed user);
    event TransferComplete(address indexed from, address indexed to);

    modifier onlyAuthorized() {
    _onlyAuthorized();
    _;
	}

    function _onlyAuthorized() internal view {
    require(authorizedContracts[msg.sender], "Not authorized");
	}

    function authorizeContract(address _contract) external {
        authorizedContracts[_contract] = true;
    }

    function deposit(uint32 _amount) external {
        euint32 amount = FHE.asEuint32(_amount);

        balances[msg.sender] = FHE.add(balances[msg.sender], amount);
        totalPool = FHE.add(totalPool, amount);

        userDeposits[msg.sender].push(Deposit({
            user: msg.sender,
            timestamp: block.timestamp
        }));

        emit Deposited(msg.sender);
    }

    function requestWithdrawal(uint32 _amount) external {
        euint32 amount = FHE.asEuint32(_amount);

        // 🔥 Will revert automatically if insufficient balance
        balances[msg.sender] = FHE.sub(balances[msg.sender], amount);
        totalPool = FHE.sub(totalPool, amount);

        userWithdrawals[msg.sender].push(Withdrawal({
            user: msg.sender,
            timestamp: block.timestamp,
            processed: false
        }));

        emit WithdrawalRequested(msg.sender);
    }

    function transfer(
        address _from,
        address _to,
        uint32 _amount
    ) external onlyAuthorized {
        require(_from != _to, "Same address");

        euint32 amount = FHE.asEuint32(_amount);

        // 🔥 Safe subtraction = implicit balance check
        balances[_from] = FHE.sub(balances[_from], amount);
        balances[_to] = FHE.add(balances[_to], amount);

        emit TransferComplete(_from, _to);
    }

    function getBalance(address _user) external view returns (euint32) {
        return balances[_user];
    }

    function getDepositCount(address _user) external view returns (uint256) {
        return userDeposits[_user].length;
    }

    function getWithdrawalCount(address _user) external view returns (uint256) {
        return userWithdrawals[_user].length;
    }

    function processWithdrawal(address _user, uint256 _id) external {
        require(_id < userWithdrawals[_user].length, "Invalid ID");

        Withdrawal storage w = userWithdrawals[_user][_id];
        require(!w.processed, "Already processed");

        w.processed = true;
    }
}
