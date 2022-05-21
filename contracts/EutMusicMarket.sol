pragma solidity >=0.6.0 <0.8.0;

// SPDX-License-Identifier: MIT

// EUT Master Contract
// Holds auctions
contract EutMusicMarket {
    // A ledger records on who owns which NFT
    // user_address => nft_address
    mapping(address => address) public ownership_ledger;

    // A ledger records which NFT owned by who
    // nft_address => user_address
    mapping(address => address) public nft_ledger;

    // Model a purchase transaction event
    struct PurchaseTransaction {
        address nft_address;
        uint price;
        uint last_transaction_time;
        uint watermark; //how many times it's been shifted hand
    }

    // A ledger records who had which transaction
    mapping(address => PurchaseTransaction) public ownership_transaction_history;

    // Number of total nft recorded
    uint public nftItemCount;


    constructor () public {
        // Pre-populate some questions
    }
}