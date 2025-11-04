# iAsset Dev Demo
A liquidity pool on supra move Tool that accepts iAssets (reward-bearing tokens on Supra blockchain).

## What are iAssets?

iAssets are yield-bearing tokens that represent deposited collateral in PoEL's IntraLayer vaults. When users deposit assets like ETH, USDC, or SUPRA, they receive corresponding iAssets (iETH, iUSDC, iSUPRA) that:

- **Earn staking rewards** from delegated $SUPRA automatically
- **Can be used in DeFi protocols** as liquidity
- **Multi-yield potential** - base staking yield + protocol-specific yield

## Why PoEL?
Proof of Efficient Liquidity (PoEL):

- Attracts external liquidity (ETH, BTC, USDC) to bootstrap Supra's DeFi dApps.
- Distributes staking rewards to iAsset holders proportionally
- Provides stimulus rewards to apps that integrate iAssets

## Architecture (How It Works)

```
┌─────────────────────────────────────────────────────────┐
│  YOUR LIQUIDITY POOL CONTRACT                           │
│  - Holds iAssets from users                             │
│  - Tracks deposit balances                              │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ (PoEL sees your contract holds iAssets)
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  PoEL MODULE (0xc4a734...0eebd)                         │
│  - Tracks iAsset holdings across ALL assets             │
│  - Calculates rewards for each holder                   │
│  - Waits for external claim requests                    │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ (YOU call these via CLI/IDE)
                 │
                 ▼
         ┌───────────────────┐
         │ update_rewards()  │ → Allocates pending rewards
         │ claim_rewards()   │ → Claims allocated reward (AFTER Cooldown)
         │ withdraw_rewards()│ → Withdraws SUPRA to your pool
         └───────────────────┘
                 │
                 ▼
         Pool receives $SUPRA tokens
                 │
                 ▼
         Distribute to your users however you want!
```

**Key Insight:** Your contract is just an iAsset holder. PoEL tracks and calculates rewards. You claim those rewards externally using CLI/IDE, then distribute to your users.

## Project Structure

```
iassets/
├── sources/
│   └── iassets_simple_pool.move        # Main pool contract (holds iAssets)
├── Move.toml                    # Package config
└── README.md                    # This file
```

## Quick Start Guide

### 1. Create Your Pool

```bash
supra move Tool run \
  --function-id 'YOUR_ADDRESS::iassets_poel_demo_j::create_pool' \
  --args object:IASSET_METADATA_ADDRESS
```

### 2. Users Deposit iAssets

```bash
supra move Tool run --function-id 'YOUR_ADDRESS::iassets_poel_demo_j::deposit_iassets' --args u64:AMOUNT
```

### 3. Check Pool Stats

```bash
supra move Tool view --function-id 'YOUR_ADDRESS::iassets_poel_demo_j::get_pool_stats
```

**Returns:** `(total_iassets_deposited, total_rewards_earned, pool_active)`

### 4. Check User Position

```bash
supra move Tool view --function-id 'YOUR_ADDRESS::iassets_poel_demo_j::get_user_position' --args address:USER_ADDRESS
```

**Returns:** `(iasset_balance, rewards_claimed)`

### 5. Verify Pool Balance On-Chain

```bash
supra move Tool view --function-id 'YOUR_ADDRESS::iassets_poel_demo_j::get_pool_iasset_balance'
```

## PoEL Reward Integration (The Important Part!)

Your contract **does NOT call PoEL functions directly**. Instead, you (the pool operator) call PoEL externally using the CLI or SDK.

### Step 1: Update Rewards

**What it does:** Syncs pending rewards and allocates them to your pool address.

```bash
supra move Tool run \
  --function-id '0xc4a734e5b84deb218ab7ba5a46af45da54d5ff4aa8846e842c3ac2e32ce0eebd::poel::update_rewards' \
  --args address:YOUR_POOL_ADDRESS object:IASSET_METADATA
```

**Check if you have allocatable rewards first:**
```bash
supra move Tool view \
  --function-id '0xc4a734e5b84deb218ab7ba5a46af45da54d5ff4aa8846e842c3ac2e32ce0eebd::iAsset::get_allocatable_rewards' \
  --args address:YOUR_POOL_ADDRESS object:IASSET_METADATA
```

### Step 2: Claim Rewards

**What it does:** Claims allocated rewards and starts a **3-day cooldown period**.

```bash
supra move Tool run \
  --function-id '0xc4a734e5b84deb218ab7ba5a46af45da54d5ff4aa8846e842c3ac2e32ce0eebd::poel::claim_rewards'
```

**Important:** After calling this, you must wait before withdrawing!

**Check your reward status:**
```bash
supra move Tool view \
  --function-id '0xc4a734e5b84deb218ab7ba5a46af45da54d5ff4aa8846e842c3ac2e32ce0eebd::iAsset::get_user_rewards' \
  --args address:YOUR_POOL_ADDRESS
  ```

**Returns:** `(allocated_rewards, withdrawable_rewards, epoch, timestamp, withdrawn_rewards)`

### Step 3: Check Cooldown Timer

**What it does:** Shows seconds remaining until you can withdraw.

```bash
supra move Tool view \
  --function-id '0xc4a734e5b84deb218ab7ba5a46af45da54d5ff4aa8846e842c3ac2e32ce0eebd::iAsset::get_withdraw_timer_for_user' \
  --args address:YOUR_POOL_ADDRESS
```

**Returns:** Number of seconds remaining

- `259200` = 3 days (just claimed)
- `4038` = ~1 hour remaining
- `0` = Ready to withdraw!

### Step 4: Withdraw Rewards

**What it does:** Transfers SUPRA tokens from PoEL vault to your pool address.

```bash
supra move Tool run \
  --function-id '0xc4a734e5b84deb218ab7ba5a46af45da54d5ff4aa8846e842c3ac2e32ce0eebd::poel::withdraw_rewards'
```

**Success!** Your pool address now has SUPRA tokens!

### Step 5: Distribute to Your Users

Now you have SUPRA in your pool. Distribute it however you want:

**Option A: Via your contract**
Build a `distribute_rewards()` function that sends proportional SUPRA to each LP.

**Option B: Manually**
Calculate each user's share and send SUPRA directly.


## View Functions

### Get Complete Pool Info
```bash
supra move Tool view \
  --function-id 'YOUR_ADDRESS::iassets_poel_demo_j::get_pool_stats'
```

### Get User's Position
```bash
supra move Tool view \
  --function-id 'YOUR_ADDRESS::iassets_poel_demo_j::get_user_position' \
  --args address:USER_ADDRESS
```

### Get Pool's Actual iAsset Balance
```bash
supra move Tool view \
  --function-id 'YOUR_ADDRESS::iassets_poel_demo_j::get_pool_iasset_balance'
```

### Get Reward Timestamps
```bash
supra move Tool view \
  --function-id 'YOUR_ADDRESS::iassets_poel_demo_j::get_reward_timestamps'
```

**Returns:** `(last_update_timestamp, last_claim_timestamp, last_withdraw_timestamp)`


## Complete Testing Flow

Here's a full example of integrating and testing:

### Setup (One-time) 

```bash
# 1. Deploy your pool contract
supra move Tool publish

# 2. Create pool for iUSDC
supra move Tool run \
  --function-id '0xYOUR_ADDR::iassets_poel_demo_j::create_pool' \
  --args object:0x7762f3583728573ad0e02367ba06d35fdd75bc6bac5985038d24f1fa4b3f661c

# 3. Deposit some iUSDC
supra move Tool run \
  --function-id '0xYOUR_ADDR::iassets_poel_demo_j::deposit_iassets' \
  --args u64:100000
```

### Major Operations

```bash
# 4. Check allocatable rewards (do this daily/weekly)
supra move Tool view \
  --function-id '0xc4a734...::iAsset::get_allocatable_rewards' \
  --args address:YOUR_POOL_ADDR object:IUSDC_METADATA

# If allocatable > 0, update rewards:
supra move Tool run \
  --function-id '0xc4a734...::poel::update_rewards' \
  --args address:YOUR_POOL_ADDR object:IUSDC_METADATA

# 5. Check allocated rewards
supra move Tool view \
  --function-id '0xc4a734...::iAsset::get_user_rewards' \
  --args address:YOUR_POOL_ADDR

# If allocated > 0, claim:
supra move Tool run \
  --function-id '0xc4a734...::poel::claim_rewards'

# 6. Wait 3 days...

# 7. Check timer
supra move Tool view \
  --function-id '0xc4a734...::iAsset::get_withdraw_timer_for_user' \
  --args address:YOUR_POOL_ADDR

# If timer == 0, withdraw!
supra move Tool run \
  --function-id '0xc4a734...::poel::withdraw_rewards'

# 8. Distribute SUPRA to your users!
```

### "Pool not found" error

Make sure you've created the pool first:
```bash
supra move Tool run --function-id 'YOUR_ADDRESS::iassets_poel_demo_j::create_pool' --args object:IASSET_METADATA
```

### "Position not found" error

User hasn't deposited yet. They need to call `deposit_iassets` first.

### View functions returning zeros

This is normal if:
- Pool hasn't been created yet
- User hasn't deposited yet
- No rewards have been claimed yet

### "E_NO_ALLOCATABLE_REWARDS" error

No rewards are available to allocate yet. This is normal if:
- Pool was just created
- Rewards were recently claimed
- Not enough time has passed since last update

Wait a few days and try again!

## Resources

**Documentation:**
- PoEL Overview: https://docs.supra.com/proof-of-efficient-liquidity-poel
- Integration Guide: https://docs.supra.com/proof-of-efficient-liquidity-poel/integration-guide
- Smart Contract Integration: https://docs.supra.com/proof-of-efficient-liquidity-poel/smart-contract-integration