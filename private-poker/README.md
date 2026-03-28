# Private Poker 🂡

A fully on-chain Texas Hold'em game with complete privacy using **Fhenix** (FHE) and **Privara**.

## 🔥 Core Features

- **Encrypted Cards**: All player hands are encrypted using Fully Homomorphic Encryption (FHE)
- **Confidential Bets**: Bet amounts and pot sizes are hidden from opponents
- **Private Balances**: Player balances remain encrypted throughout the game
- **MEV Protection**: No front-running or bet leakage
- **True Bluffing**: Strategic privacy preserved
- **Optional Reveal**: Winners can choose to reveal their hand for credibility

## 🏗 Architecture

### 1. Smart Contracts (Fhenix)

**PokerEngine.sol** - Core game logic:
- Player management
- Encrypted card dealing
- Betting rounds (Pre-flop, Flop, Turn, River)
- Encrypted hand evaluation
- Winner determination

**PrivaraPaymentGateway.sol** - Payment layer:
- Confidential deposits/withdrawals
- Private pot tracking
- Hidden payouts

### 2. Frontend (React + COFHE SDK)

Custom hooks for:
- `useEncrypt` - Encrypt player actions
- `useDecrypt` - Decrypt own cards and results
- `usePokerEngine` - Contract interactions
- `usePokerGame` - Game state management

## 🎮 Game Flow

```
1. Buy-in (Privara)
   └─> Player deposits encrypted stablecoins
   
2. Card Dealing (FHE)
   └─> Encrypted deck generated on-chain
   └─> Each player receives 2 encrypted hole cards
   
3. Betting Rounds
   ├─> Pre-flop
   ├─> Flop (3 community cards)
   ├─> Turn (1 community card)
   ├─> River (1 community card)
   └─> All bets are encrypted
   
4. Hand Evaluation (FHE)
   └─> Contract computes winner without revealing cards
   
5. Payout (Privara)
   └─> Winner receives encrypted payout
```

## 📁 Project Structure

```
private-poker/
├── contracts/
│   ├── PokerEngine.sol          # Main game contract
│   └── PrivaraPaymentGateway.sol # Payment layer
├── frontend/
│   └── src/
│       └── usePoker.ts          # React hooks
├── test/                        # Test files
└── scripts/                     # Deployment scripts
```

## 🔐 Privacy Model

| Data | Visibility |
|------|-----------|
| Player cards | Only owner can decrypt |
| Community cards | Revealed gradually |
| Bets | Hidden (encrypted) |
| Pot size | Hidden (encrypted) |
| Winner | Public |
| Winning hand | Optional reveal |

## 🚀 Getting Started

### Prerequisites

- Node.js 18+
- Foundry (for Solidity development)
- Fhenix network access
- COFHE SDK installed

### Installation

```bash
# Install dependencies
npm install

# Install Fhenix dependencies
npm install fhenixjs cofhe-sdk
```

### Deploy Contracts

```bash
# Compile contracts
forge build

# Deploy to Fhenix testnet
forge script scripts/Deploy.s.sol --rpc-url <fhenix-rpc> --broadcast
```

### Run Frontend

```bash
cd frontend
npm install
npm run dev
```

## 🧪 Testing

```bash
# Run tests
forge test

# With verbosity
forge test -vvv
```

## 🛡 Security Considerations

1. **FHE Randomness**: Use proper FHE random number generation for card shuffling
2. **Access Control**: Implement role-based permissions for admin functions
3. **Reentrancy Guards**: Protect against reentrancy attacks in payment functions
4. **Gas Optimization**: Minimize FHE operations where possible

## 🎯 Key Innovations

### ✅ MEV-Protected Betting
No one can front-run your bets or see them before execution.

### ✅ True Bluffing
Bet sizes remain private, preserving strategic depth.

### ✅ Optional Reveal Mode
Winners can reveal their hand for credibility or keep strategy secret.

### ✅ Compliance Layer (Privara)
- Audit keys for regulatory compliance
- KYC-gated tables (optional)

## 📄 License

MIT

## 🤝 Contributing

Contributions welcome! Please read our contributing guidelines before submitting PRs.

---

**Built with ❤️ using Fhenix + Privara**

*No dealer. No trust. No leaks.*
