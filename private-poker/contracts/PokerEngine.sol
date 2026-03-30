// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32 } from "@fhenixprotocol/contracts/FHE.sol";


contract PokerEngine {
    using FHE for euint32;

    enum GameState { Waiting, Active, Finished }

    struct Player {
        address addr;
        euint32 balance;
        euint32 currentBet;
        bool isActive;
    }

    struct Table {
        address[] players;
        mapping(address => Player) playerData;
        euint32 pot;
        GameState state;
        uint8 currentPlayerIndex;
        uint256 minBet;
        bool active;
    }

    mapping(uint256 => Table) public tables;
    uint256 public tableCount;

    event TableCreated(uint256 indexed tableId);
    event PlayerJoined(uint256 indexed tableId, address player);
    event GameStarted(uint256 indexed tableId);
    event BetPlaced(uint256 indexed tableId, address player);
    event RoundEnded(uint256 indexed tableId, address winner);

    function createTable(uint256 _minBet) external returns (uint256) {
        require(_minBet > 0, "Invalid bet");

        uint256 tableId = tableCount++;
        Table storage table = tables[tableId];

        table.minBet = _minBet;
        table.active = true;
        table.state = GameState.Waiting;
        table.pot = FHE.asEuint32(0);

        emit TableCreated(tableId);
        return tableId;
    }

    function joinTable(uint256 _tableId, uint32 _buyIn) external {
        Table storage table = tables[_tableId];

        require(table.active, "Inactive table");
        require(table.state == GameState.Waiting, "Game started");

        table.players.push(msg.sender);

        Player storage player = table.playerData[msg.sender];
        player.addr = msg.sender;
        player.balance = FHE.asEuint32(_buyIn);
        player.currentBet = FHE.asEuint32(0);
        player.isActive = true;

        emit PlayerJoined(_tableId, msg.sender);
    }

    function startGame(uint256 _tableId) external {
        Table storage table = tables[_tableId];

        require(table.players.length >= 2, "Need players");
        require(table.state == GameState.Waiting, "Already started");

        table.state = GameState.Active;
        table.currentPlayerIndex = 0;

        emit GameStarted(_tableId);
    }

    function placeBet(uint256 _tableId, uint32 _amount) external {
        Table storage table = tables[_tableId];
        require(table.state == GameState.Active, "Not active");

        Player storage player = table.playerData[msg.sender];
        require(player.isActive, "Not player");

        euint32 amount = FHE.asEuint32(_amount);

        // 🔥 This will revert automatically if insufficient balance
        player.balance = FHE.sub(player.balance, amount);

        player.currentBet = FHE.add(player.currentBet, amount);
        table.pot = FHE.add(table.pot, amount);

        emit BetPlaced(_tableId, msg.sender);

        _nextPlayer(_tableId);
    }

    function endRound(uint256 _tableId) external {
        Table storage table = tables[_tableId];
        require(table.state == GameState.Active, "Not active");

        // MVP: first player wins
        address winner = table.players[0];

        table.playerData[winner].balance =
            FHE.add(table.playerData[winner].balance, table.pot);

        table.pot = FHE.asEuint32(0);
        table.state = GameState.Finished;

        emit RoundEnded(_tableId, winner);
    }

    function _nextPlayer(uint256 _tableId) internal {
        Table storage table = tables[_tableId];

        table.currentPlayerIndex =
            uint8((table.currentPlayerIndex + 1) % table.players.length);
    }

    function getPlayers(uint256 _tableId) external view returns (address[] memory) {
        return tables[_tableId].players;
    }

    function getPot(uint256 _tableId) external view returns (euint32) {
        return tables[_tableId].pot;
    }

    function getMyBalance(uint256 _tableId) external view returns (euint32) {
        return tables[_tableId].playerData[msg.sender].balance;
    }
}
