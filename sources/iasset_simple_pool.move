module demo_addr::iasset_pool {
    use std::signer;
    use supra_framework::object::Object;
    use supra_framework::fungible_asset::Metadata;
    
    const POEL_MODULE: address = @0xc4a734e5b84deb218ab7ba5a46af45da54d5ff4aa8846e842c3ac2e32ce0eebd;
    const E_POOL_NOT_FOUND: u64 = 1;
    const E_POSITION_NOT_FOUND: u64 = 2;
    const E_POOL_NOT_ACTIVE: u64 = 3;
    const E_ZERO_AMOUNT: u64 = 4;
    
    struct SimplePool has key {
        total_iassets_deposited: u64,
        total_rewards_earned: u64,
        pool_active: bool,
    }
    
    struct LiquidityPosition has key {
        iasset_balance: u64,
        rewards_claimed: u64,
    }
    
    public entry fun create_pool(admin: &signer) {
        move_to(admin, SimplePool {
            total_iassets_deposited: 0,
            total_rewards_earned: 0,
            pool_active: true,
        });
    }
    
    public entry fun deposit_iassets(
        user: &signer,
        amount: u64
    ) acquires SimplePool, LiquidityPosition {
        assert!(amount > 0, E_ZERO_AMOUNT);
        let user_addr = signer::address_of(user);
        assert!(exists<SimplePool>(@demo_addr), E_POOL_NOT_FOUND);
        let pool = borrow_global<SimplePool>(@demo_addr);
        assert!(pool.pool_active, E_POOL_NOT_ACTIVE);
        
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
    
    public entry fun step1_update_rewards(
        _pool_owner: &signer,
        _iasset_metadata: Object<Metadata>
    ) acquires SimplePool {
        let _pool = borrow_global_mut<SimplePool>(@demo_addr);
    }
    
    public entry fun step2_claim_rewards(
        _pool_owner: &signer
    ) acquires SimplePool {
        let _pool = borrow_global_mut<SimplePool>(@demo_addr);
    }
    
    public entry fun step3_withdraw_rewards(
        _pool_owner: &signer
    ) acquires SimplePool {
        let pool = borrow_global_mut<SimplePool>(@demo_addr);
        pool.total_rewards_earned = pool.total_rewards_earned + 1000;
    }
    
    public entry fun distribute_rewards_to_lps(
        _pool_owner: &signer,
        user: address,
        reward_amount: u64
    ) acquires LiquidityPosition, SimplePool {
        let pool = borrow_global<SimplePool>(@demo_addr);
        
        if (pool.total_iassets_deposited == 0) {
            return
        };
        
        if (!exists<LiquidityPosition>(user)) {
            return
        };
        
        let user_position = borrow_global_mut<LiquidityPosition>(user);
        
        let user_share = (user_position.iasset_balance * reward_amount) 
                        / pool.total_iassets_deposited;
        
        user_position.rewards_claimed = user_position.rewards_claimed + user_share;
    }

    #[view]
    public fun get_pool_stats(): (u64, u64, bool) acquires SimplePool {
        if (!exists<SimplePool>(@demo_addr)) {
            return (0, 0, false)
        };
        
        let pool = borrow_global<SimplePool>(@demo_addr);
        (
            pool.total_iassets_deposited,
            pool.total_rewards_earned,
            pool.pool_active
        )
    }
    
    #[view]
    public fun is_pool_active(): bool acquires SimplePool {
        if (!exists<SimplePool>(@demo_addr)) {
            return false
        };
        borrow_global<SimplePool>(@demo_addr).pool_active
    }

    #[view]
    public fun get_user_position(user: address): (u64, u64) acquires LiquidityPosition {
        if (!exists<LiquidityPosition>(user)) {
            return (0, 0)
        };
        
        let position = borrow_global<LiquidityPosition>(user);
        (
            position.iasset_balance,
            position.rewards_claimed
        )
    }
    
    #[view]
    public fun has_position(user: address): bool {
        exists<LiquidityPosition>(user)
    }
    

    #[view]
    public fun get_user_pool_share(user: address): u64 acquires SimplePool, LiquidityPosition {
        if (!exists<SimplePool>(@demo_addr) || !exists<LiquidityPosition>(user)) {
            return 0
        };
        
        let pool = borrow_global<SimplePool>(@demo_addr);
        if (pool.total_iassets_deposited == 0) {
            return 0
        };
        
        let position = borrow_global<LiquidityPosition>(user);
        (position.iasset_balance * 10000) / pool.total_iassets_deposited
    }
    
    #[view]
    public fun calculate_user_reward_share(
        user: address, 
        total_rewards_to_distribute: u64
    ): u64 acquires SimplePool, LiquidityPosition {
        if (!exists<SimplePool>(@demo_addr) || !exists<LiquidityPosition>(user)) {
            return 0
        };
        
        let pool = borrow_global<SimplePool>(@demo_addr);
        if (pool.total_iassets_deposited == 0) {
            return 0
        };
        
        let position = borrow_global<LiquidityPosition>(user);
        (position.iasset_balance * total_rewards_to_distribute) / pool.total_iassets_deposited
    }
    
    #[view]
    public fun get_total_deposited(): u64 acquires SimplePool {
        if (!exists<SimplePool>(@demo_addr)) {
            return 0
        };
        borrow_global<SimplePool>(@demo_addr).total_iassets_deposited
    }
    
    #[view]
    public fun get_total_rewards(): u64 acquires SimplePool {
        if (!exists<SimplePool>(@demo_addr)) {
            return 0
        };
        borrow_global<SimplePool>(@demo_addr).total_rewards_earned
    }
    
    #[view]
    public fun get_comprehensive_pool_info(): (u64, u64, bool, bool) acquires SimplePool {
        if (!exists<SimplePool>(@demo_addr)) {
            return (0, 0, false, false)
        };
        
        let pool = borrow_global<SimplePool>(@demo_addr);
        (
            pool.total_iassets_deposited,
            pool.total_rewards_earned,
            pool.pool_active,
            true
        )
    }
    
    #[view]
    public fun get_user_dashboard_info(
        user: address,
        estimated_next_reward_amount: u64
    ): (u64, u64, u64, u64) acquires SimplePool, LiquidityPosition {
        if (!exists<LiquidityPosition>(user)) {
            return (0, 0, 0, 0)
        };
        
        if (!exists<SimplePool>(@demo_addr)) {
            return (0, 0, 0, 0)
        };
        
        let pool = borrow_global<SimplePool>(@demo_addr);
        let position = borrow_global<LiquidityPosition>(user);
        
        let pool_share = if (pool.total_iassets_deposited == 0) {
            0
        } else {
            (position.iasset_balance * 10000) / pool.total_iassets_deposited
        };
        
        let estimated_reward = if (pool.total_iassets_deposited == 0) {
            0
        } else {
            (position.iasset_balance * estimated_next_reward_amount) / pool.total_iassets_deposited
        };
        
        (
            position.iasset_balance,
            position.rewards_claimed,
            pool_share,
            estimated_reward
        )
    }
}