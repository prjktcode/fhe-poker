import { useState, useEffect } from 'react';
import { useAccount, useWriteContract, useReadContract } from 'wagmi';
import { encrypt, decrypt } from 'cofhe-sdk';

// Contract ABIs (simplified)
const POKER_ENGINE_ABI = [
  {
    "inputs": [{"name": "_minBet", "type": "uint256"}, {"name": "_maxPlayers", "type": "uint256"}],
    "name": "createTable",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"name": "_tableId", "type": "uint256"}, {"name": "_initialBalance", "type": "euint"}],
    "name": "joinTable",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"name": "_tableId", "type": "uint256"}],
    "name": "startGame",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "_tableId", "type": "uint256"},
      {"name": "_amount", "type": "euint"},
      {"name": "_fold", "type": "bool"}
    ],
    "name": "placeBet",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

const PRIVARA_GATEWAY_ABI = [
  {
    "inputs": [{"name": "_amount", "type": "euint"}],
    "name": "deposit",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"name": "_amount", "type": "euint"}],
    "name": "requestWithdrawal",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

/**
 * Hook for encrypting data using COFHE SDK
 */
export function useEncrypt() {
  const [encryptedData, setEncryptedData] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const encrypt = async (value: number | bigint, bitSize: number = 32) => {
    setIsLoading(true);
    setError(null);
    
    try {
      // Using COFHE SDK to encrypt values
      const result = await encrypt({
        value: BigInt(value),
        bitSize: bitSize
      });
      
      setEncryptedData(result);
      return result;
    } catch (err) {
      setError(err);
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  return { encrypt, encryptedData, isLoading, error };
}

/**
 * Hook for decrypting data using COFHE SDK
 */
export function useDecrypt() {
  const [decryptedData, setDecryptedData] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const decrypt = async (encryptedValue: any) => {
    setIsLoading(true);
    setError(null);
    
    try {
      const result = await decrypt(encryptedValue);
      setDecryptedData(result);
      return result;
    } catch (err) {
      setError(err);
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  return { decrypt, decryptedData, isLoading, error };
}

/**
 * Hook for interacting with PokerEngine contract
 */
export function usePokerEngine(contractAddress: string) {
  const { address: userAddress } = useAccount();
  const { writeContract } = useWriteContract();
  
  // Create a new table
  const createTable = async (minBet: number, maxPlayers: number) => {
    writeContract({
      address: contractAddress as `0x${string}`,
      abi: POKER_ENGINE_ABI,
      functionName: 'createTable',
      args: [BigInt(minBet), BigInt(maxPlayers)]
    });
  };

  // Join an existing table
  const joinTable = async (tableId: number, balance: number) => {
    const { encrypt } = await import('cofhe-sdk');
    const encryptedBalance = await encrypt({ value: BigInt(balance), bitSize: 32 });
    
    writeContract({
      address: contractAddress as `0x${string}`,
      abi: POKER_ENGINE_ABI,
      functionName: 'joinTable',
      args: [BigInt(tableId), encryptedBalance]
    });
  };

  // Start the game
  const startGame = (tableId: number) => {
    writeContract({
      address: contractAddress as `0x${string}`,
      abi: POKER_ENGINE_ABI,
      functionName: 'startGame',
      args: [BigInt(tableId)]
    });
  };

  // Place a bet
  const placeBet = async (tableId: number, amount: number, fold: boolean) => {
    const { encrypt } = await import('cofhe-sdk');
    const encryptedAmount = await encrypt({ value: BigInt(amount), bitSize: 32 });
    
    writeContract({
      address: contractAddress as `0x${string}`,
      abi: POKER_ENGINE_ABI,
      functionName: 'placeBet',
      args: [BigInt(tableId), encryptedAmount, fold]
    });
  };

  return { createTable, joinTable, startGame, placeBet };
}

/**
 * Hook for interacting with Privara Payment Gateway
 */
export function usePrivaraGateway(contractAddress: string) {
  const { writeContract } = useWriteContract();

  // Deposit funds
  const deposit = async (amount: number) => {
    const { encrypt } = await import('cofhe-sdk');
    const encryptedAmount = await encrypt({ value: BigInt(amount), bitSize: 32 });
    
    writeContract({
      address: contractAddress as `0x${string}`,
      abi: PRIVARA_GATEWAY_ABI,
      functionName: 'deposit',
      args: [encryptedAmount]
    });
  };

  // Request withdrawal
  const requestWithdrawal = async (amount: number) => {
    const { encrypt } = await import('cofhe-sdk');
    const encryptedAmount = await encrypt({ value: BigInt(amount), bitSize: 32 });
    
    writeContract({
      address: contractAddress as `0x${string}`,
      abi: PRIVARA_GATEWAY_ABI,
      functionName: 'requestWithdrawal',
      args: [encryptedAmount]
    });
  };

  return { deposit, requestWithdrawal };
}

/**
 * Hook for managing poker game state
 */
export function usePokerGame(pokerEngineAddress: string, privaraAddress: string) {
  const { address: userAddress } = useAccount();
  const pokerEngine = usePokerEngine(pokerEngineAddress);
  const privara = usePrivaraGateway(privaraAddress);
  const { decrypt } = useDecrypt();
  
  const [currentTable, setCurrentTable] = useState<number | null>(null);
  const [myCards, setMyCards] = useState<{ card1: number; card2: number } | null>(null);
  const [gameState, setGameState] = useState<string>('Waiting');

  // Initialize game session
  const initializeSession = async () => {
    // Check if user has balance in Privara
    // If not, prompt for deposit
  };

  // Create or join table
  const joinOrCreateTable = async (tableId?: number, minBet: number = 100, maxPlayers: number = 6) => {
    if (tableId !== undefined) {
      // Join existing table
      await privara.deposit(minBet * 10); // Deposit 10x min bet
      await pokerEngine.joinTable(tableId, minBet * 10);
      setCurrentTable(tableId);
    } else {
      // Create new table
      const tableId = await pokerEngine.createTable(minBet, maxPlayers);
      setCurrentTable(tableId);
    }
  };

  // Start the game
  const startGameSession = async () => {
    if (currentTable !== null) {
      await pokerEngine.startGame(currentTable);
      // After game starts, player can decrypt their own cards
      await fetchMyCards();
    }
  };

  // Fetch and decrypt player's cards
  const fetchMyCards = async () => {
    if (currentTable === null || !userAddress) return;
    
    // In production, read encrypted cards from contract and decrypt
    // This is simplified - actual implementation would use contract reads
    console.log('Fetching encrypted cards for:', userAddress);
  };

  // Make a move (bet, call, raise, fold)
  const makeMove = async (action: 'bet' | 'call' | 'raise' | 'fold', amount: number = 0) => {
    if (currentTable === null) return;
    
    const isFold = action === 'fold';
    await pokerEngine.placeBet(currentTable, amount, isFold);
  };

  return {
    currentTable,
    myCards,
    gameState,
    initializeSession,
    joinOrCreateTable,
    startGameSession,
    makeMove,
    fetchMyCards
  };
}

export default {
  useEncrypt,
  useDecrypt,
  usePokerEngine,
  usePrivaraGateway,
  usePokerGame
};
