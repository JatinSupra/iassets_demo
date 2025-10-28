# iAsset Simple Pool Demo

iAssets are reward-bearing tokens native to the Supra blockchain that represent deposited collateral in PoEL's IntraLayer vaults. When users deposit assets like ETH, USDC, or SUPRA, they receive corresponding iAssets (iETH, iUSDC, iSUPRA) that:

- Earn staking rewards from delegated $SUPRA
- Can be used in DeFi protocols as liquidity
- Are redeemable for the underlying asset (coming soon)

## Why PoEL?

Proof of Efficient Liquidity (PoEL):

- Attracts external liquidity to bootstrap Supra's DeFi ecosystem
- Uses deposited assets as collateral to borrow and delegate $SUPRA
- Distributes staking rewards to iAsset holders
- Incentivizes deployment of iAssets in liquidity pools

## Architecture
```
┌─────────────────┐
│  User's Wallet  │
│   (iAssets)     │
└────────┬────────┘
         │ deposit
         ▼
┌─────────────────────────────────┐
│   iAsset Simple Pool (this!)    │
│  - Tracks deposits               │
│  - Claims PoEL rewards           │
│  - Distributes to LPs            │
└────────┬────────────────────────┘
         │ integration
         ▼
┌─────────────────────────────────┐
│      PoEL Protocol              │
│  - Allocates rewards             │
│  - Manages delegation            │
│  - Handles reward claims         │
└─────────────────────────────────┘
```

## Project Structure
```
iassets/
├── sources/
│   ├── iassets_pool.move  
│   └── iasset_vault.move        
├── Move.toml                   
└── README.md                     
```

## Usage Guide

### 1. Initialize the Pool
```bash
supra move run \
  --function-id 'YOUR_ADDRESS::iassets_pool::create_pool' \
  --url https://rpc-testnet.supra.com
```

### 2. Deposit iAssets
```bash
# Deposit 1000 iAssets
supra move run \
  --function-id 'YOUR_ADDRESS::iassets_pool::deposit_iassets' \
  --args u64:1000 \
  --url https://rpc-testnet.supra.com
```

### 3. View Pool Statistics
```bash
# Get comprehensive pool info
supra move view \
  --function-id 'YOUR_ADDRESS::iassets_pool::get_comprehensive_pool_info' \
  --url https://rpc-testnet.supra.com
```

**Returns:** `[total_deposited, total_rewards, is_active, pool_exists]`

Example output: `[1000, 0, true, true]`

### 4. Check Your Position
```bash
# View your liquidity position
supra move view \
  --function-id 'YOUR_ADDRESS::iassets_pool::get_user_position' \
  --args address:YOUR_ADDRESS \
  --url https://rpc-testnet.supra.com
```

**Returns:** `[iasset_balance, rewards_claimed]`

### 5. View Dashboard Info
```bash
# Get complete dashboard (balance, rewards, share%, estimated)
supra move view \
  --function-id 'YOUR_ADDRESS::iassets_pool::get_user_dashboard_info' \
  --args address:YOUR_ADDRESS u64:5000 \
  --url https://rpc-testnet.supra.com
```

**Returns:** `[balance, claimed, share_percentage, estimated_rewards]`

Example: `[1000, 0, 10000, 5000]` means:
- 1000 iAssets deposited
- 0 rewards claimed
- 10000 = 100.00% pool ownership
- 5000 estimated rewards if distributing 5000 SUPRA

## PoEL Integration Flow

### Step 1: Update Rewards
```bash
supra move run \
  --function-id 'YOUR_ADDRESS::iassets_pool::step1_update_rewards' \
  --args object:IASSET_METADATA_ADDRESS \
  --url https://rpc-testnet.supra.com
```

Syncs allocatable rewards → allocated rewards for the pool.

### Step 2: Claim Rewards
```bash
supra move run \
  --function-id 'YOUR_ADDRESS::iassets_pool::step2_claim_rewards' \
  --url https://rpc-testnet.supra.com
```

Moves allocated rewards → withdrawable rewards.

### Step 3: Withdraw Rewards
```bash
supra move run \
  --function-id 'YOUR_ADDRESS::iassets_pool::step3_withdraw_rewards' \
  --url https://rpc-testnet.supra.com
```

Pulls rewards from PoEL vault to the pool.

### Step 4: Distribute to LPs
```bash
supra move run \
  --function-id 'YOUR_ADDRESS::iassets_pool::distribute_rewards_to_lps' \
  --args address:LP_ADDRESS u64:REWARD_AMOUNT \
  --url https://rpc-testnet.supra.com
```

Distributes pool rewards proportionally to liquidity providers.

## Demo Scenarios

### Scenario 1: Single User Pool
```bash
# 1. Create pool
supra move run --function-id 'YOUR_ADDRESS::iassets_pool::create_pool'

# 2. Deposit
supra move run --function-id 'YOUR_ADDRESS::iassets_pool::deposit_iassets' --args u64:1000

# 3. Check stats
supra move view --function-id 'YOUR_ADDRESS::iassets_pool::get_pool_stats'
# Output: [1000, 0, true] - 1000 deposited, 0 rewards, active

# 4. View position
supra move view --function-id 'YOUR_ADDRESS::iassets_pool::get_user_position' --args address:YOUR_ADDR
# Output: [1000, 0] - 1000 balance, 0 claimed

# 5. Check share
supra move view --function-id 'YOUR_ADDRESS::iassets_pool::get_user_pool_share' --args address:YOUR_ADDR
# Output: 10000 - 100% ownership
```

### Scenario 2: Multi-User Pool
```bash
# User A deposits 1000
supra move run --function-id 'YOUR_ADDRESS::iassets_pool::deposit_iassets' --args u64:1000

# User B deposits 3000
supra move run --function-id 'YOUR_ADDRESS::iassets_pool::deposit_iassets' --args u64:3000

# Check User A's share
supra move view --function-id 'YOUR_ADDRESS::iassets_pool::get_user_pool_share' --args address:USER_A
# Output: 2500 - 25% ownership

# Check User B's share
supra move view --function-id 'YOUR_ADDRESS::iassets_pool::get_user_pool_share' --args address:USER_B
# Output: 7500 - 75% ownership
```

### Scenario 3: Reward Distribution
```bash
# Simulate 1000 SUPRA rewards
# User A (25% share) should get 250 SUPRA
supra move view --function-id 'YOUR_ADDRESS::iassets_pool::calculate_user_reward_share' \
  --args address:USER_A u64:1000
# Output: 250

# User B (75% share) should get 750 SUPRA
supra move view --function-id 'YOUR_ADDRESS::iassets_pool::calculate_user_reward_share' \
  --args address:USER_B u64:1000
# Output: 750
```

#### "Pool not found" error

Make sure you've created the pool first:
```bash
supra move run --function-id 'YOUR_ADDRESS::iassets_pool::create_pool'
```

#### "Position not found" error

User hasn't deposited yet. Check with:
```bash
supra move view --function-id 'YOUR_ADDRESS::iassets_pool::has_position' --args address:USER_ADDR
```

## View functions returning zeros
This is normal if:
- Pool hasn't been created yet
- User hasn't deposited yet
- No rewards have been distributed yet

## iAsset Balance vs Rewards
- **iAsset Balance:** The amount of iAssets deposited in the pool
- **Rewards Claimed:** SUPRA rewards earned from PoEL delegation
- These are separate! Users deposit iAssets, earn SUPRA rewards

## Reward Flow
```
PoEL Delegation → Staking Rewards → Pool Claims → Distribute to LPs
```

## Docs
- Read the [PoEL paper](https://docs.supra.com/proof-of-efficient-liquidity-poel)
- Check [Supra documentation](https://docs.supra.com)