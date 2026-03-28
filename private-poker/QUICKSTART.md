# 🂡 Private Poker - Quick Start Guide

## ✅ Tests Passed Successfully!

All 10 core logic tests passed:
- Table Creation ✅
- Player Management ✅
- Card Dealing ✅
- Betting Rounds ✅
- Fold Logic ✅
- Community Cards ✅
- Winner Determination ✅
- Deposits ✅
- Withdrawals ✅
- Balance Validation ✅

---

## 🚀 Run Tests Again

```bash
cd /workspace/private-poker
npm test
```

---

## 📦 Project Structure

```
private-poker/
├── contracts/
│   ├── PokerEngine.sol          # Core game logic with FHE
│   └── PrivaraPaymentGateway.sol # Confidential payments
├── frontend/
│   ├── src/
│   │   ├── App.jsx              # React UI component
│   │   ├── main.jsx             # Entry point
│   │   └── usePoker.ts          # React hooks for encryption
│   ├── index.html
│   ├── package.json
│   └── vite.config.js
├── test/
│   └── poker.test.js            # Test suite (✅ Passing)
├── scripts/
│   ├── deploy.js                # Deployment guide
│   └── Deploy.s.sol             # Foundry deployment script
├── foundry.toml                 # Foundry config
├── package.json                 # Root package
└── README.md                    # Full documentation
```

---

## 🔧 Next Steps

### Option 1: Deploy to Fhenix Testnet

1. **Install Foundry**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Install Fhenix Solidity Library**
   ```bash
   cd /workspace/private-poker
   forge install fhenixprotocol/fhenix-solidity
   ```

3. **Set Environment Variables**
   ```bash
   export FHENIX_RPC_URL="https://api.helium.fhenix.zone"
   export PRIVATE_KEY="your-wallet-private-key"
   ```

4. **Deploy Contracts**
   ```bash
   forge build
   forge script scripts/Deploy.s.sol:DeployScript --rpc-url $FHENIX_RPC_URL --broadcast
   ```

5. **Update Frontend .env**
   ```bash
   cp frontend/.env.example frontend/.env
   # Edit with deployed contract addresses
   ```

6. **Run Frontend**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

---

### Option 2: Review Code

- **Smart Contracts**: `/workspace/private-poker/contracts/`
  - `PokerEngine.sol` - Encrypted poker logic
  - `PrivaraPaymentGateway.sol` - Confidential payments

- **Frontend Hooks**: `/workspace/private-poker/frontend/src/usePoker.ts`
  - `useEncrypt` - Encrypt player actions
  - `useDecrypt` - Decrypt own cards
  - `usePokerGame` - Game state management

- **Tests**: `/workspace/private-poker/test/poker.test.js`
  - Simulates encrypted behavior
  - Validates all game flows

---

## 📖 Documentation

See `README.md` for complete documentation including:
- Architecture overview
- Privacy model
- Game flow
- Security considerations
- API reference

---

## 🔗 Resources

- **Fhenix Docs**: https://docs.fhenix.zone
- **Privara Docs**: https://docs.privara.io
- **COFHE SDK**: https://github.com/fhenixprotocol/cofhe-sdk
- **Fhenix Faucet**: https://faucet.fhenix.zone

---

**No dealer. No trust. No leaks.** 🎰
