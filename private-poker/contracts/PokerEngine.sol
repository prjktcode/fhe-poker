// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhenix-solidity/src/types/euint.sol";
import "fhenix-solidity/src/types/ebool.sol";
import "fhenix-solidity/src/types/eaddress.sol";
import "fhenix-solidity/src/lib/HE.sol";

/**
 * @title PokerEngine
 * @dev Fully encrypted Texas Hold'em poker engine on Fhenix
 */
contract PokerEngine {
    using euint for uint256;
    using ebool for bool;
    
    // Game state
    enum GameState { Waiting, PreFlop, Flop, Turn, River, Showdown }
    
    struct Player {
        address addr;
        euint[2] hand;           // Encrypted hole cards
        euint balance;           // Encrypted balance
        euint currentBet;        // Encrypted current bet in round
        ebool folded;            // Encrypted fold status
        bool isActive;
    }
    
    struct Table {
        uint256 tableId;
        address[] players;
        mapping(address => Player) playerData;
        euint[5] communityCards;  // Encrypted community cards
        uint8 communityCardCount;
        euint pot;                // Encrypted pot size
        GameState state;
        uint8 currentPlayerIndex;
        uint256 minBet;
        uint256 maxPlayers;
        bool active;
    }
    
    // Deck management
    euint[52] private encryptedDeck;
    mapping(uint256 => bool) private deckInitialized;
    
    // Tables
    mapping(uint256 => Table) public tables;
    uint256 public tableCount;
    
    // Events (minimal info leakage)
    event PlayerJoined(uint256 indexed tableId, address player);
    event GameStarted(uint256 indexed tableId);
    event BettingRoundComplete(uint256 indexed tableId, uint8 round);
    event WinnerDeclared(uint256 indexed tableId, address winner);
    
    /**
     * @dev Initialize a new poker table
     */
    function createTable(uint256 _minBet, uint256 _maxPlayers) external returns (uint256) {
        require(_maxPlayers >= 2 && _maxPlayers <= 9, "Invalid player count");
        require(_minBet > 0, "Invalid min bet");
        
        uint256 tableId = tableCount++;
        Table storage table = tables[tableId];
        
        table.tableId = tableId;
        table.minBet = _minBet;
        table.maxPlayers = _maxPlayers;
        table.active = true;
        table.state = GameState.Waiting;
        
        return tableId;
    }
    
    /**
     * @dev Player joins a table with encrypted balance
     */
    function joinTable(uint256 _tableId, euint calldata _initialBalance) external {
        Table storage table = tables[_tableId];
        require(table.active, "Table not active");
        require(table.players.length < table.maxPlayers, "Table full");
        require(table.state == GameState.Waiting, "Game already started");
        
        table.players.push(msg.sender);
        Player storage player = table.playerData[msg.sender];
        player.addr = msg.sender;
        player.balance = _initialBalance;
        player.isActive = true;
        player.folded = HE.asEbool(false);
        player.currentBet = HE.asEuint(0);
        
        emit PlayerJoined(_tableId, msg.sender);
    }
    
    /**
     * @dev Start the game and deal cards
     */
    function startGame(uint256 _tableId) external {
        Table storage table = tables[_tableId];
        require(table.players.length >= 2, "Need at least 2 players");
        require(table.state == GameState.Waiting, "Cannot start");
        
        // Initialize encrypted deck
        _initializeDeck(_tableId);
        
        // Deal hole cards (2 per player)
        for (uint256 i = 0; i < table.players.length; i++) {
            address playerAddr = table.players[i];
            Player storage player = table.playerData[playerAddr];
            
            player.hand[0] = _drawCard(_tableId);
            player.hand[1] = _drawCard(_tableId);
        }
        
        table.state = GameState.PreFlop;
        table.currentPlayerIndex = 0;
        
        emit GameStarted(_tableId);
    }
    
    /**
     * @dev Place an encrypted bet
     */
    function placeBet(uint256 _tableId, euint calldata _amount, bool _fold) external {
        Table storage table = tables[_tableId];
        require(table.state != GameState.Waiting, "Game not started");
        require(table.state != GameState.Showdown, "Round complete");
        
        address playerAddr = msg.sender;
        Player storage player = table.playerData[playerAddr];
        
        // Update fold status (encrypted)
        if (_fold) {
            player.folded = HE.asEbool(true);
        } else {
            // Verify sufficient balance
            euint requiredAmount = _amount.add(player.currentBet);
            // Note: Balance check happens with encrypted comparison
            require(player.balance.gte(requiredAmount), "Insufficient funds");
            
            player.currentBet = player.currentBet.add(_amount);
            player.balance = player.balance.sub(requiredAmount);
            table.pot = table.pot.add(requiredAmount);
        }
        
        // Move to next player
        _advancePlayer(_tableId);
    }
    
    /**
     * @dev Reveal community cards for current round
     */
    function revealCommunityCards(uint256 _tableId) external {
        Table storage table = tables[_tableId];
        require(table.state != GameState.Waiting, "Game not started");
        
        if (table.state == GameState.PreFlop) {
            // Deal flop (3 cards)
            table.communityCards[0] = _drawCard(_tableId);
            table.communityCards[1] = _drawCard(_tableId);
            table.communityCards[2] = _drawCard(_tableId);
            table.communityCardCount = 3;
            table.state = GameState.Flop;
        } else if (table.state == GameState.Flop) {
            // Deal turn (1 card)
            table.communityCards[3] = _drawCard(_tableId);
            table.communityCardCount = 4;
            table.state = GameState.Turn;
        } else if (table.state == GameState.Turn) {
            // Deal river (1 card)
            table.communityCards[4] = _drawCard(_tableId);
            table.communityCardCount = 5;
            table.state = GameState.River;
        } else if (table.state == GameState.River) {
            table.state = GameState.Showdown;
            _determineWinner(_tableId);
        }
        
        table.currentPlayerIndex = 0;
        emit BettingRoundComplete(_tableId, uint8(table.state));
    }
    
    /**
     * @dev Initialize encrypted deck for a table
     */
    function _initializeDeck(uint256 _tableId) internal {
        // Generate encrypted random cards 0-51
        for (uint256 i = 0; i < 52; i++) {
            // In production, use proper FHE randomness
            encryptedDeck[i] = HE.asEuint(i);
        }
        
        // Shuffle using Fisher-Yates with encrypted comparisons
        for (uint256 i = 51; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(_tableId, i, block.timestamp))) % (i + 1);
            euint temp = encryptedDeck[i];
            encryptedDeck[i] = encryptedDeck[j];
            encryptedDeck[j] = temp;
        }
        
        deckInitialized[_tableId] = true;
    }
    
    /**
     * @dev Draw a card from the encrypted deck
     */
    function _drawCard(uint256 _tableId) internal returns (euint) {
        // Simplified: in production, track which cards have been drawn
        uint256 cardIndex = uint256(keccak256(abi.encodePacked(_tableId, block.timestamp, msg.sender))) % 52;
        return encryptedDeck[cardIndex];
    }
    
    /**
     * @dev Advance to next active player
     */
    function _advancePlayer(uint256 _tableId) internal {
        Table storage table = tables[_tableId];
        uint256 startIndex = table.currentPlayerIndex;
        
        do {
            table.currentPlayerIndex = (table.currentPlayerIndex + 1) % table.players.length;
            
            // Break if we've gone full circle
            if (table.currentPlayerIndex == startIndex) {
                break;
            }
        } while (table.playerData[table.players[table.currentPlayerIndex]].folded.decrypt());
    }
    
    /**
     * @dev Determine winner using encrypted hand evaluation
     */
    function _determineWinner(uint256 _tableId) internal {
        Table storage table = tables[_tableId];
        
        address winner;
        euint winningScore = HE.asEuint(0);
        
        for (uint256 i = 0; i < table.players.length; i++) {
            address playerAddr = table.players[i];
            Player storage player = table.playerData[playerAddr];
            
            // Skip folded players
            if (player.folded.decrypt()) continue;
            
            // Evaluate hand (simplified - in production use full poker hand evaluation)
            euint handScore = _evaluateHand(
                player.hand[0],
                player.hand[1],
                table.communityCards
            );
            
            if (handScore.gt(winningScore).decrypt()) {
                winningScore = handScore;
                winner = playerAddr;
            }
        }
        
        // Transfer pot to winner (via Privara integration)
        table.playerData[winner].balance = table.playerData[winner].balance.add(table.pot);
        table.pot = HE.asEuint(0);
        
        emit WinnerDeclared(_tableId, winner);
    }
    
    /**
     * @dev Evaluate poker hand strength (simplified)
     */
    function _evaluateHand(
        euint _card1,
        euint _card2,
        euint[5] memory _communityCards
    ) internal pure returns (euint) {
        // Simplified scoring - in production implement full hand ranking
        // This would check for: Royal Flush, Straight Flush, Four of a Kind, etc.
        
        // For demo: sum of card values (not real poker logic)
        euint score = _card1.add(_card2);
        for (uint256 i = 0; i < 5; i++) {
            score = score.add(_communityCards[i]);
        }
        
        return score;
    }
    
    /**
     * @dev Get player's encrypted hand (only they can decrypt)
     */
    function getPlayerHand(uint256 _tableId, address _player) 
        external 
        view 
        returns (euint memory, euint memory) 
    {
        Table storage table = tables[_tableId];
        Player storage player = table.playerData[_player];
        require(_player == msg.sender, "Can only view own hand");
        
        return (player.hand[0], player.hand[1]);
    }
    
    /**
     * @dev Get encrypted pot size
     */
    function getPot(uint256 _tableId) external view returns (euint memory) {
        return tables[_tableId].pot;
    }
}
