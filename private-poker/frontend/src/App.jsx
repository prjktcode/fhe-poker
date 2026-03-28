import React, { useState } from 'react';
import { usePokerGame } from './usePoker';

// Mock contract addresses (replace with actual deployed addresses)
const POKER_ENGINE_ADDRESS = import.meta.env.VITE_POKER_ENGINE_ADDRESS || '0x...';
const PRIVARA_ADDRESS = import.meta.env.VITE_PRIVARA_GATEWAY_ADDRESS || '0x...';

function App() {
  const [status, setStatus] = useState('Ready to play!');
  
  // Note: In production, wrap with WagmiProvider and configure Fhenix network
  // const pokerGame = usePokerGame(POKER_ENGINE_ADDRESS, PRIVARA_ADDRESS);

  return (
    <div style={{ padding: '40px', maxWidth: '800px', margin: '0 auto' }}>
      <h1 style={{ marginBottom: '10px' }}>🂡 Private Poker</h1>
      <p style={{ color: '#888', marginBottom: '30px' }}>
        Fully encrypted Texas Hold'em on Fhenix + Privara
      </p>

      <div style={{ 
        background: 'rgba(255,255,255,0.05)', 
        padding: '30px', 
        borderRadius: '12px',
        marginBottom: '20px'
      }}>
        <h2 style={{ marginBottom: '15px' }}>🎮 Game Status</h2>
        <p>{status}</p>
      </div>

      <div style={{ 
        background: 'rgba(255,255,255,0.05)', 
        padding: '30px', 
        borderRadius: '12px',
        marginBottom: '20px'
      }}>
        <h2 style={{ marginBottom: '15px' }}>🔐 Privacy Features</h2>
        <ul style={{ lineHeight: '2', color: '#ccc' }}>
          <li>✅ Encrypted hole cards (FHE)</li>
          <li>✅ Hidden bet amounts</li>
          <li>✅ Private pot size</li>
          <li>✅ Confidential balances (Privara)</li>
          <li>✅ MEV-protected actions</li>
          <li>✅ True bluffing enabled</li>
        </ul>
      </div>

      <div style={{ 
        background: 'rgba(255,255,255,0.05)', 
        padding: '30px', 
        borderRadius: '12px'
      }}>
        <h2 style={{ marginBottom: '15px' }}>🚀 Next Steps</h2>
        <ol style={{ lineHeight: '2', color: '#ccc' }}>
          <li>Install Foundry: <code>curl -L https://foundry.paradigm.xyz | bash</code></li>
          <li>Deploy contracts: <code>node scripts/deploy.js</code></li>
          <li>Update .env with contract addresses</li>
          <li>Connect wallet and start playing!</li>
        </ol>
      </div>

      <div style={{ marginTop: '30px', textAlign: 'center', color: '#666' }}>
        <p>Built with ❤️ using Fhenix + Privara</p>
        <p style={{ fontSize: '12px' }}>No dealer. No trust. No leaks.</p>
      </div>
    </div>
  );
}

export default App;
