import { useState, useEffect } from 'react';
import { useAccount, useWriteContract } from 'wagmi';
import { cofhejs, Encryptable } from 'cofhejs/web'; // browser-specific entry point

// Contract ABIs
const POKER_ENGINE_ABI = [
  { inputs:[{name:"_minBet",type:"uint256"},{name:"_maxPlayers",type:"uint256"}], name:"createTable", outputs:[{name:"",type:"uint256"}], stateMutability:"nonpayable", type:"function" },
  { inputs:[{name:"_tableId",type:"uint256"},{name:"_initialBalance",type:"euint"}], name:"joinTable", outputs:[], stateMutability:"nonpayable", type:"function" },
  { inputs:[{name:"_tableId",type:"uint256"}], name:"startGame", outputs:[], stateMutability:"nonpayable", type:"function" },
  { inputs:[{name:"_tableId",type:"uint256"},{name:"_amount",type:"euint"},{name:"_fold",type:"bool"}], name:"placeBet", outputs:[], stateMutability:"nonpayable", type:"function" }
];

const PRIVARA_GATEWAY_ABI = [
  { inputs:[{name:"_amount",type:"euint"}], name:"deposit", outputs:[{name:"",type:"uint256"}], stateMutability:"nonpayable", type:"function" },
  { inputs:[{name:"_amount",type:"euint"}], name:"requestWithdrawal", outputs:[{name:"",type:"uint256"}], stateMutability:"nonpayable", type:"function" }
];

// Initialize cofhejs once (can re-init on account change)
export async function initializeCofhe(userProvider: any, userSigner: any) {
  await cofhejs.initialize({ provider: userProvider, signer: userSigner });
}

// Encrypt / Decrypt hooks
export function useEncrypt() {
  const [encryptedData, setEncryptedData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<any>(null);

  const encrypt = async (value: number | bigint) => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await cofhejs.encrypt(Encryptable.uint32(value));
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

export function useDecrypt() {
  const [decryptedData, setDecryptedData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<any>(null);

  const decrypt = async (encryptedValue: any) => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await cofhejs.decrypt(encryptedValue);
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

// Poker Engine hook
export function usePokerEngine(contractAddress: string) {
  const { writeContract } = useWriteContract();

  const createTable = async (minBet: number, maxPlayers: number) => {
    return writeContract({
      address: contractAddress as `0x${string}`,
      abi: POKER_ENGINE_ABI,
      functionName: 'createTable',
      args: [BigInt(minBet), BigInt(maxPlayers)]
    });
  };

  const joinTable = async (tableId: number, balance: number) => {
    const encryptedBalance = await cofhejs.encrypt(Encryptable.uint32(balance));
    return writeContract({
      address: contractAddress as `0x${string}`,
      abi: POKER_ENGINE_ABI,
      functionName: 'joinTable',
      args: [BigInt(tableId), encryptedBalance]
    });
  };

  const startGame = async (tableId: number) => {
    return writeContract({
      address: contractAddress as `0x${string}`,
      abi: POKER_ENGINE_ABI,
      functionName: 'startGame',
      args: [BigInt(tableId)]
    });
  };

  const placeBet = async (tableId: number, amount: number, fold: boolean) => {
    const encryptedAmount = await cofhejs.encrypt(Encryptable.uint32(amount));
    return writeContract({
      address: contractAddress as `0x${string}`,
      abi: POKER_ENGINE_ABI,
      functionName: 'placeBet',
      args: [BigInt(tableId), encryptedAmount, fold]
    });
  };

  return { createTable, joinTable, startGame, placeBet };
}

// Privara Payment Gateway hook
export function usePrivaraGateway(contractAddress: string) {
  const { writeContract } = useWriteContract();

  const deposit = async (amount: number) => {
    const encryptedAmount = await cofhejs.encrypt(Encryptable.uint32(amount));
    return writeContract({
      address: contractAddress as `0x${string}`,
      abi: PRIVARA_GATEWAY_ABI,
      functionName: 'deposit',
      args: [encryptedAmount]
    });
  };

  const requestWithdrawal = async (amount: number) => {
    const encryptedAmount = await cofhejs.encrypt(Encryptable.uint32(amount));
    return writeContract({
      address: contractAddress as `0x${string}`,
      abi: PRIVARA_GATEWAY_ABI,
      functionName: 'requestWithdrawal',
      args: [encryptedAmount]
    });
  };

  return { deposit, requestWithdrawal };
}

// Poker Game Manager
export function usePokerGame(pokerEngineAddress: string, privaraAddress: string) {
  const { address: userAddress } = useAccount();
  const pokerEngine = usePokerEngine(pokerEngineAddress);
  const privara = usePrivaraGateway(privaraAddress);
  const { decrypt } = useDecrypt();

  const [currentTable, setCurrentTable] = useState<number | null>(null);
  const [gameState, setGameState] = useState<string>('Waiting');

  const joinOrCreateTable = async (tableId?: number, minBet: number = 100, maxPlayers: number = 6) => {
    if (tableId) {
      await privara.deposit(minBet * 10);
      await pokerEngine.joinTable(tableId, minBet * 10);
      setCurrentTable(tableId);
    } else {
      const newTableId = await pokerEngine.createTable(minBet, maxPlayers);
      setCurrentTable(Number(newTableId));
    }
  };

  const startGameSession = async () => {
    if (currentTable !== null) {
      await pokerEngine.startGame(currentTable);
    }
  };

  const makeMove = async (action: 'bet' | 'call' | 'raise' | 'fold', amount: number = 0) => {
    if (currentTable === null) return;
    const fold = action === 'fold';
    await pokerEngine.placeBet(currentTable, amount, fold);
  };

  return { currentTable, gameState, joinOrCreateTable, startGameSession, makeMove, decrypt };
}
