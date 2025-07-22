# ArtByte NFT Marketplace

A decentralized NFT marketplace smart contract built on the Stacks blockchain using Clarity. This contract enables artists to mint NFTs, list them for sale, and collectors to purchase them with built-in royalty distribution.

## Features

- **NFT Minting**: Artists can mint unique NFTs with custom metadata
- **Marketplace**: Built-in marketplace for buying and selling NFTs
- **Royalty System**: Automatic royalty payments to original artists on secondary sales
- **Admin Controls**: Administrative functions for contract management
- **Secure Transactions**: Built-in validation and error handling

## Contract Overview

The ArtByte NFT Marketplace consists of several key components:

### NFT Asset
- **Token Type**: `artbyte-nft` (Non-Fungible Token)
- **Token ID**: Sequential uint starting from 1

### Data Structures

#### Registry Map
Stores NFT metadata and ownership information:
```clarity
{ id: uint } -> { 
  holder: principal, 
  minter: principal, 
  metadata: (string-ascii 256), 
  fee: uint 
}
```

#### Market Map
Stores active marketplace listings:
```clarity
{ id: uint } -> { 
  cost: uint, 
  vendor: principal 
}
```

## Functions

### Administrative Functions

#### `update-admin`
Transfer admin rights to a new principal.
- **Parameters**: `new-admin` (principal)
- **Access**: Admin only
- **Returns**: `(response bool uint)`

#### `view-admin`
View the current admin principal.
- **Parameters**: None
- **Access**: Read-only
- **Returns**: `(response principal uint)`

### NFT Functions

#### `create-token`
Mint a new NFT with metadata and royalty fee.
- **Parameters**: 
  - `meta` (string-ascii 256): Token metadata/URI
  - `fee` (uint): Royalty fee in basis points (max 1000 = 10%)
- **Access**: Public
- **Returns**: `(response uint uint)` - Returns token ID on success

#### `token-info`
Retrieve token metadata and ownership information.
- **Parameters**: `id` (uint): Token ID
- **Access**: Read-only
- **Returns**: `(response {holder: principal, minter: principal, metadata: (string-ascii 256), fee: uint} uint)`

### Marketplace Functions

#### `open-offer`
List an NFT for sale on the marketplace.
- **Parameters**:
  - `id` (uint): Token ID
  - `cost` (uint): Sale price in microSTX
- **Access**: Token owner only
- **Returns**: `(response bool uint)`

#### `revoke-offer`
Remove an NFT listing from the marketplace.
- **Parameters**: `id` (uint): Token ID
- **Access**: Listing owner only
- **Returns**: `(response bool uint)`

#### `purchase`
Purchase an NFT from the marketplace.
- **Parameters**: `id` (uint): Token ID
- **Access**: Public (except token owner)
- **Returns**: `(response bool uint)`
- **Payment**: Automatically transfers STX to seller and royalties to original minter

#### `offer-info`
View marketplace listing details.
- **Parameters**: `id` (uint): Token ID
- **Access**: Read-only
- **Returns**: `(response {cost: uint, vendor: principal} uint)`

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-not-admin` | Caller is not the admin |
| u101 | `err-not-holder` | Caller is not the token holder |
| u102 | `err-no-offer` | No marketplace listing exists |
| u103 | `err-bad-price` | Invalid price (must be > 0) |
| u104 | `err-bad-token` | Invalid or non-existent token |
| u105 | `err-bad-uri` | Invalid metadata URI (empty string) |
| u106 | `err-bad-royalty` | Invalid royalty fee (> 10%) |
| u107 | `err-invalid-principal` | Invalid principal address |

## Usage Examples

### Minting an NFT
```clarity
;; Mint an NFT with 5% royalty fee
(contract-call? .artbyte-marketplace create-token "https://myart.com/metadata.json" u500)
```

### Listing for Sale
```clarity
;; List token ID 1 for 1000 microSTX
(contract-call? .artbyte-marketplace open-offer u1 u1000)
```

### Purchasing an NFT
```clarity
;; Purchase token ID 1
(contract-call? .artbyte-marketplace purchase u1)
```

### Checking Token Info
```clarity
;; Get information about token ID 1
(contract-call? .artbyte-marketplace token-info u1)
```

## Royalty System

The contract implements an automatic royalty system:
- Artists set a royalty fee (in basis points) when minting
- Maximum royalty is 10% (1000 basis points)
- On each sale, royalties are automatically paid to the original minter
- Remaining amount goes to the seller

### Royalty Calculation
```
royalty = (sale_price * royalty_fee) / 10000
seller_payout = sale_price - royalty
```

## Security Features

- **Ownership Validation**: Only token owners can list for sale
- **Principal Validation**: Prevents invalid addresses
- **Price Validation**: Ensures positive sale prices
- **Admin Controls**: Protected administrative functions
- **Automatic Transfers**: Secure STX and NFT transfers

## Deployment

1. Deploy the contract to the Stacks blockchain
2. The deploying principal becomes the initial admin
3. Artists can immediately start minting NFTs
4. The marketplace is ready for trading

## Integration

This contract can be integrated into web applications using:
- **Stacks.js**: For JavaScript/TypeScript applications
- **Clarinet**: For local development and testing
- **Stacks APIs**: For querying blockchain state

