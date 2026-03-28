// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/PokerEngine.sol";
import "../contracts/PrivaraPaymentGateway.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy PrivaraPaymentGateway first
        PrivaraPaymentGateway privara = new PrivaraPaymentGateway();
        console.log("PrivaraPaymentGateway deployed at:", address(privara));
        
        // Deploy PokerEngine
        PokerEngine poker = new PokerEngine();
        console.log("PokerEngine deployed at:", address(poker));
        
        // Authorize PokerEngine to use Privara
        privara.authorizeContract(address(poker));
        console.log("PokerEngine authorized on PrivaraPaymentGateway");
        
        vm.stopBroadcast();
        
        // Output for frontend configuration
        console.log("\n=== Deployment Complete ===");
        console.log("FHENIX_RPC_URL=https://api.helium.fhenix.zone");
        console.log("VITE_PRIVARA_GATEWAY_ADDRESS=", address(privara));
        console.log("VITE_POKER_ENGINE_ADDRESS=", address(poker));
    }
}
