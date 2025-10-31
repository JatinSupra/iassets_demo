module demo_addr::iassets_poel_demo_j {
    use std::signer;
    use supra_framework::object::{Self, Object, ExtendRef};
    use supra_framework::fungible_asset::{Self, Metadata, FungibleStore};
    use supra_framework::dispatchable_fungible_asset;
    use supra_framework::primary_fungible_store;
    use supra_framework::timestamp;
    
    // Error codes
    const E_POOL_NOT_FOUND: u64 = 1;
    const E_POOL_NOT_ACTIVE: u64 = 3;
    const E_ZERO_AMOUNT: u64 = 4;
    const E_INSUFFICIENT_BALANCE: u64 = 5;
    const E_NOT_AUTHORIZED: u64 = 6;
    const E_POOL_ALREADY_EXISTS: u64 = 7;
    
    struct SimplePool has key {
        total_iassets_deposited: u64,
        total_rewards_earned: u64,
        pool_active: bool,
        iasset_store: Object<FungibleStore>,
        iasset_store_extend_ref: ExtendRef,
        iasset_metadata: Object<Metadata>,
        last_update_timestamp: u64,
        last_claim_timestamp: u64,
        last_withdraw_timestamp: u64,
    }
    
    struct LiquidityPosition has key {
        iasset_balance: u64,
        rewards_claimed: u64,
    }

    /// Create a new liquidity pool for a specific iAsset
    public entry fun create_pool(
        admin: &signer,
        iasset_metadata: Object<Metadata>
    ) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @demo_addr, E_NOT_AUTHORIZED);
        assert!(!exists<SimplePool>(@demo_addr), E_POOL_ALREADY_EXISTS);
        
        let store_constructor_ref = &object::create_object(admin_addr);
        let iasset_store = fungible_asset::create_store(store_constructor_ref, iasset_metadata);
        let iasset_store_extend_ref = object::generate_extend_ref(store_constructor_ref);
        
        move_to(admin, SimplePool {
            total_iassets_deposited: 0,
            total_rewards_earned: 0,
            pool_active: true,
            iasset_store,
            iasset_store_extend_ref,
            iasset_metadata,
            last_update_timestamp: 0,
            last_claim_timestamp: 0,
            last_withdraw_timestamp: 0,
        });
    }
    
    /// Deposit iAssets into the pool
    public entry fun deposit_iassets(
        user: &signer,
        amount: u64
    ) acquires SimplePool, LiquidityPosition {
        assert!(amount > 0, E_ZERO_AMOUNT);
        let user_addr = signer::address_of(user);
        
        assert!(exists<SimplePool>(@demo_addr), E_POOL_NOT_FOUND);
        let pool = borrow_global<SimplePool>(@demo_addr);
        assert!(pool.pool_active, E_POOL_NOT_ACTIVE);
        
        let user_primary_store = primary_fungible_store::ensure_primary_store_exists(
            user_addr, 
            pool.iasset_metadata
        );
        let iasset = dispatchable_fungible_asset::withdraw(
            user, 
            user_primary_store,
            amount
        );
        
        dispatchable_fungible_asset::deposit(pool.iasset_store, iasset);
        
        if (!exists<LiquidityPosition>(user_addr)) {
            move_to(user, LiquidityPosition {
                iasset_balance: 0,
                rewards_claimed: 0,
            });
        };
        
        let pool_mut = borrow_global_mut<SimplePool>(@demo_addr);
        pool_mut.total_iassets_deposited = pool_mut.total_iassets_deposited + amount;
        
        let position = borrow_global_mut<LiquidityPosition>(user_addr);
        position.iasset_balance = position.iasset_balance + amount;
    }

    /// Withdraw iAssets from the pool
    public entry fun withdraw_iassets(
        user: &signer,
        amount: u64
    ) acquires SimplePool, LiquidityPosition {
        let user_addr = signer::address_of(user);
        assert!(exists<SimplePool>(@demo_addr), E_POOL_NOT_FOUND);
        assert!(exists<LiquidityPosition>(user_addr), E_INSUFFICIENT_BALANCE);
        
        let user_position = borrow_global_mut<LiquidityPosition>(user_addr);
        assert!(user_position.iasset_balance >= amount, E_INSUFFICIENT_BALANCE);
        
        let pool = borrow_global<SimplePool>(@demo_addr);
        
        let store_signer = &object::generate_signer_for_extending(&pool.iasset_store_extend_ref);
        let iasset = dispatchable_fungible_asset::withdraw(
            store_signer, 
            pool.iasset_store, 
            amount
        );
        
        let user_primary_store = primary_fungible_store::ensure_primary_store_exists(
            user_addr, 
            pool.iasset_metadata
        );
        dispatchable_fungible_asset::deposit(user_primary_store, iasset);
        
        let pool_mut = borrow_global_mut<SimplePool>(@demo_addr);
        pool_mut.total_iassets_deposited = pool_mut.total_iassets_deposited - amount;
        
        user_position.iasset_balance = user_position.iasset_balance - amount;
    }
    
    #[view]
    public fun get_pool_stats(): (u64, u64, bool) acquires SimplePool {
        if (!exists<SimplePool>(@demo_addr)) {
            return (0, 0, false)
        };
        let pool = borrow_global<SimplePool>(@demo_addr);
        (pool.total_iassets_deposited, pool.total_rewards_earned, pool.pool_active)
    }
    
    #[view]
    public fun get_user_position(user: address): (u64, u64) acquires LiquidityPosition {
        if (!exists<LiquidityPosition>(user)) {
            return (0, 0)
        };
        let position = borrow_global<LiquidityPosition>(user);
        (position.iasset_balance, position.rewards_claimed)
    }
    
    #[view]
    public fun get_pool_iasset_balance(): u64 acquires SimplePool {
        if (!exists<SimplePool>(@demo_addr)) {
            return 0
        };
        let pool = borrow_global<SimplePool>(@demo_addr);
        fungible_asset::balance(pool.iasset_store)
    }
    
    #[view]
    public fun get_reward_timestamps(): (u64, u64, u64) acquires SimplePool {
        if (!exists<SimplePool>(@demo_addr)) {
            return (0, 0, 0)
        };
        let pool = borrow_global<SimplePool>(@demo_addr);
        (pool.last_update_timestamp, pool.last_claim_timestamp, pool.last_withdraw_timestamp)
    }
}
