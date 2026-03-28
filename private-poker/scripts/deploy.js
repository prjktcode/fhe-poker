/**
 * Private Poker - Deployment Script
 * 
 * This script demonstrates how to deploy the contracts to Fhenix network
 * Note: Requires Foundry (forge) and Fhenix network access
 */

console.log('\n========================================');
console.log('🂡 PRIVATE POKER - DEPLOYMENT GUIDE 🂡');
console.log('========================================\n');

console.log('📋 Prerequisites:');
console.log('  1. Install Foundry:');
console.log('     curl -L https://foundry.paradigm.xyz | bash');
console.log('     foundryup\n');
console.log('  2. Get Fhenix testnet tokens from faucet');
console.log('  3. Set up environment variables:\n');
console.log('     export FHENIX_RPC_URL="https://api.helium.fhenix.zone"');
console.log('     export PRIVATE_KEY="your-private-key"\n');

console.log('🚀 Deployment Steps:\n');

console.log('Step 1: Install Fhenix Solidity Library');
console.log('----------------------------------------');
console.log('cd /workspace/private-poker');
console.log('forge install fhenixprotocol/fhenix-solidity\n');

console.log('Step 2: Compile Contracts');
console.log('----------------------------------------');
console.log('forge build\n');
console.log('// Expected output:');
console.log('//   Compiler run successful!');
console.log('//   Artifacts written to out/\n');

console.log('Step 3: Deploy PrivaraPaymentGateway');
console.log('----------------------------------------');
console.log('forge script scripts/Deploy.s.sol:DeployScript --rpc-url $FHENIX_RPC_URL --broadcast\n');
console.log('// Save the deployed address for next step\n');

console.log('Step 4: Deploy PokerEngine');
console.log('----------------------------------------');
console.log('// Update Deploy.s.sol with PrivaraPaymentGateway address');
console.log('forge script scripts/Deploy.s.sol:DeployScript --rpc-url $FHENIX_RPC_URL --broadcast\n');

console.log('Step 5: Verify Contracts (Optional)');
console.log('----------------------------------------');
console.log('forge verify-contract <CONTRACT_ADDRESS> PokerEngine --chain-id 8008135\n');

console.log('========================================');
console.log('📝 Post-Deployment Configuration');
console.log('========================================\n');

console.log('Update frontend/.env with:');
console.log('----------------------------------------');
console.log('VITE_POKER_ENGINE_ADDRESS=<deployed-address>');
console.log('VITE_PRIVARA_GATEWAY_ADDRESS=<deployed-address>');
console.log('VITE_FHENIX_RPC_URL=https://api.helium.fhenix.zone\n');

console.log('========================================');
console.log('🎮 Testing on Testnet');
console.log('========================================\n');

console.log('1. Get test tokens from Fhenix faucet');
console.log('2. Connect wallet to frontend');
console.log('3. Deposit funds via PrivaraPaymentGateway');
console.log('4. Create a table');
console.log('5. Join table with encrypted balance');
console.log('6. Start game and play!\n');

console.log('========================================');
console.log('🔗 Useful Links');
console.log('========================================\n');
console.log('Fhenix Docs: https://docs.fhenix.zone');
console.log('Privara Docs: https://docs.privara.io');
console.log('COFHE SDK: https://github.com/fhenixprotocol/cofhe-sdk');
console.log('Fhenix Faucet: https://faucet.fhenix.zone\n');

console.log('========================================');
console.log('✅ Ready to Deploy!');
console.log('========================================\n');

// Export deployment configuration
const deploymentConfig = {
  network: {
    name: 'fhenix_testnet',
    chainId: 8008135,
    rpcUrl: 'https://api.helium.fhenix.zone'
  },
  contracts: {
    PokerEngine: {
      path: 'contracts/PokerEngine.sol',
      args: []
    },
    PrivaraPaymentGateway: {
      path: 'contracts/PrivaraPaymentGateway.sol',
      args: []
    }
  },
  dependencies: [
    'fhenix-solidity'
  ]
};

console.log('Deployment Config:', JSON.stringify(deploymentConfig, null, 2));
console.log('\n');
