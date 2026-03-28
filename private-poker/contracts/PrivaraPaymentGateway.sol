// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhenix-solidity/src/types/euint.sol";
import "fhenix-solidity/src/types/ebool.sol";
import "fhenix-solidity/src/lib/HE.sol";

/**
 * @title PrivaraPaymentGateway
 * @dev Confidential payment layer for Private Poker using Privara
 */
contract PrivaraPaymentGateway {
    using euint for uint256;
    using ebool for bool;
    
    struct Deposit {
        address user;
        euint amount;
        uint256 timestamp;
        bool claimed;
    }
    
    struct Withdrawal {
        address user;
        euint amount;
        uint256 timestamp;
        bool processed;
    }
    
    // Encrypted balances
    mapping(address => euint) public encryptedBalances;
    
    // Deposit and withdrawal tracking
    mapping(address => Deposit[]) public userDeposits;
    mapping(address => Withdrawal[]) public userWithdrawals;
    
    // Total pool (encrypted)
    euint public totalPool;
    
    // Authorized poker contracts
    mapping(address => bool) public authorizedContracts;
    
    // Events
    event Deposited(address indexed user, uint256 depositId);
    event WithdrawalRequested(address indexed user, uint256 withdrawalId);
    event TransferComplete(address indexed from, address indexed to);
    
    modifier onlyAuthorized() {
        require(authorizedContracts[msg.sender], "Not authorized");
        _;
    }
    
    /**
     * @dev Authorize a poker contract to use this payment gateway
     */
    function authorizeContract(address _contract) external {
        // In production, add access control (e.g., onlyOwner)
        authorizedContracts[_contract] = true;
    }
    
    /**
     * @dev Deposit funds with encrypted amount
     */
    function deposit(euint calldata _amount) external returns (uint256) {
        require(_amount.gt(HE.asEuint(0)).decrypt(), "Amount must be positive");
        
        // Update user's encrypted balance
        if (encryptedBalances[msg.sender].decrypt() == 0) {
            encryptedBalances[msg.sender] = _amount;
        } else {
            encryptedBalances[msg.sender] = encryptedBalances[msg.sender].add(_amount);
        }
        
        // Update total pool
        totalPool = totalPool.add(_amount);
        
        // Record deposit
        userDeposits[msg.sender].push(Deposit({
            user: msg.sender,
            amount: _amount,
            timestamp: block.timestamp,
            claimed: false
        }));
        
        emit Deposited(msg.sender, userDeposits[msg.sender].length - 1);
        
        return userDeposits[msg.sender].length - 1;
    }
    
    /**
     * @dev Request withdrawal with encrypted amount
     */
    function requestWithdrawal(euint calldata _amount) external returns (uint256) {
        require(_amount.gt(HE.asEuint(0)).decrypt(), "Amount must be positive");
        
        // Verify sufficient balance
        require(
            encryptedBalances[msg.sender].gte(_amount).decrypt(),
            "Insufficient balance"
        );
        
        // Deduct from balance
        encryptedBalances[msg.sender] = encryptedBalances[msg.sender].sub(_amount);
        totalPool = totalPool.sub(_amount);
        
        // Record withdrawal request
        userWithdrawals[msg.sender].push(Withdrawal({
            user: msg.sender,
            amount: _amount,
            timestamp: block.timestamp,
            processed: false
        }));
        
        emit WithdrawalRequested(msg.sender, userWithdrawals[msg.sender].length - 1);
        
        return userWithdrawals[msg.sender].length - 1;
    }
    
    /**
     * @dev Transfer funds between users (for poker payouts)
     * Only callable by authorized poker contracts
     */
    function transfer(address _from, address _to, euint calldata _amount) external onlyAuthorized {
        require(_from != _to, "Cannot transfer to self");
        require(
            encryptedBalances[_from].gte(_amount).decrypt(),
            "Insufficient sender balance"
        );
        
        // Deduct from sender
        encryptedBalances[_from] = encryptedBalances[_from].sub(_amount);
        
        // Add to recipient
        if (encryptedBalances[_to].decrypt() == 0) {
            encryptedBalances[_to] = _amount;
        } else {
            encryptedBalances[_to] = encryptedBalances[_to].add(_amount);
        }
        
        emit TransferComplete(_from, _to);
    }
    
    /**
     * @dev Get user's encrypted balance
     */
    function getBalance(address _user) external view returns (euint memory) {
        return encryptedBalances[_user];
    }
    
    /**
     * @dev Get user's deposit history count
     */
    function getDepositCount(address _user) external view returns (uint256) {
        return userDeposits[_user].length;
    }
    
    /**
     * @dev Get user's withdrawal history count
     */
    function getWithdrawalCount(address _user) external view returns (uint256) {
        return userWithdrawals[_user].length;
    }
    
    /**
     * @dev Process a withdrawal (admin function)
     * In production, this would integrate with Privara's confidential payout system
     */
    function processWithdrawal(address _user, uint256 _withdrawalId) external {
        // In production, add admin access control
        require(_withdrawalId < userWithdrawals[_user].length, "Invalid withdrawal ID");
        
        Withdrawal storage withdrawal = userWithdrawals[_user][_withdrawalId];
        require(!withdrawal.processed, "Already processed");
        
        withdrawal.processed = true;
        
        // In production: trigger actual payout via Privara
        // For now, just mark as processed
    }
}
