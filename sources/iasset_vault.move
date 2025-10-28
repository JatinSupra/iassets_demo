module demo_addr::iassets_vault {
    use std::signer;
    use supra_framework::fungible_asset::{Self, Metadata, FungibleStore};
    use supra_framework::object::{Self, Object, ExtendRef};
    use supra_framework::primary_fungible_store;
    use supra_framework::timestamp;
    
    const POEL_ADDRESS: address = @0xc4a734e5b84deb218ab7ba5a46af45da54d5ff4aa8846e842c3ac2e32ce0eebd;
    
    const E_NOT_INITIALIZED: u64 = 1;
    const E_ALREADY_INITIALIZED: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_NO_REWARDS_AVAILABLE: u64 = 4;
    const E_COOLDOWN_NOT_EXPIRED: u64 = 5;
    
    struct UserPosition has key {
        deposited_amount: u64,
        last_deposit_time: u64,
        reward_share: u64,
    }
    
    struct VaultState has key {
        total_deposited: u64,
        total_rewards_claimed: u64,
        last_reward_update: u64,
        vault_store: Object<FungibleStore>,
        vault_store_extend_ref: ExtendRef,
    }
    
    public entry fun initialize(
        admin: &signer,
        iasset_metadata: Object<Metadata>
    ) {
        let admin_addr = signer::address_of(admin);
        assert!(!exists<VaultState>(admin_addr), E_ALREADY_INITIALIZED);
        
        let store_constructor_ref = &object::create_object(admin_addr);
        let vault_store = fungible_asset::create_store(store_constructor_ref, iasset_metadata);
        let vault_store_extend_ref = object::generate_extend_ref(store_constructor_ref);
        
        move_to(admin, VaultState {
            total_deposited: 0,
            total_rewards_claimed: 0,
            last_reward_update: timestamp::now_seconds(),
            vault_store,
            vault_store_extend_ref,
        });
    }
    
    public entry fun deposit(
        user: &signer,
        vault_owner: address,
        iasset_metadata: Object<Metadata>,
        amount: u64
    ) acquires VaultState, UserPosition {
        let user_addr = signer::address_of(user);
        assert!(exists<VaultState>(vault_owner), E_NOT_INITIALIZED);
        
        if (!exists<UserPosition>(user_addr)) {
            move_to(user, UserPosition {
                deposited_amount: 0,
                last_deposit_time: timestamp::now_seconds(),
                reward_share: 0,
            });
        };
        
        let iasset = primary_fungible_store::withdraw(user, iasset_metadata, amount);
        fungible_asset::deposit(
            borrow_global<VaultState>(vault_owner).vault_store,
            iasset
        );
        
        let vault_state = borrow_global_mut<VaultState>(vault_owner);
        vault_state.total_deposited = vault_state.total_deposited + amount;
        
        let user_position = borrow_global_mut<UserPosition>(user_addr);
        user_position.deposited_amount = user_position.deposited_amount + amount;
        user_position.last_deposit_time = timestamp::now_seconds();
    }
    
    public entry fun withdraw(
        user: &signer,
        vault_owner: address,
        iasset_metadata: Object<Metadata>,
        amount: u64
    ) acquires VaultState, UserPosition {
        let user_addr = signer::address_of(user);
        assert!(exists<VaultState>(vault_owner), E_NOT_INITIALIZED);
        assert!(exists<UserPosition>(user_addr), E_INSUFFICIENT_BALANCE);
        
        let user_position = borrow_global_mut<UserPosition>(user_addr);
        assert!(user_position.deposited_amount >= amount, E_INSUFFICIENT_BALANCE);
        
        let vault_state = borrow_global<VaultState>(vault_owner);
        let store_signer = &object::generate_signer_for_extending(&vault_state.vault_store_extend_ref);
        let iasset = fungible_asset::withdraw(store_signer, vault_state.vault_store, amount);
        
        primary_fungible_store::deposit(user_addr, iasset);
        
        let vault_state_mut = borrow_global_mut<VaultState>(vault_owner);
        vault_state_mut.total_deposited = vault_state_mut.total_deposited - amount;
        
        user_position.deposited_amount = user_position.deposited_amount - amount;
    }
    
    public fun check_allocatable_rewards(
        vault_owner: address,
        iasset_metadata: Object<Metadata>
    ): u64 {
        0
    }
    
    public entry fun update_vault_rewards(
        vault_owner: &signer,
        iasset_metadata: Object<Metadata>
    ) acquires VaultState {
        let owner_addr = signer::address_of(vault_owner);
        assert!(exists<VaultState>(owner_addr), E_NOT_INITIALIZED);
        
        let allocatable = check_allocatable_rewards(owner_addr, iasset_metadata);
        
        if (allocatable > 0) {
            let vault_state = borrow_global_mut<VaultState>(owner_addr);
            vault_state.last_reward_update = timestamp::now_seconds();
        };
    }
    
    public entry fun claim_vault_rewards(
        vault_owner: &signer
    ) acquires VaultState {
        let owner_addr = signer::address_of(vault_owner);
        assert!(exists<VaultState>(owner_addr), E_NOT_INITIALIZED);
        
        let vault_state = borrow_global_mut<VaultState>(owner_addr);
        vault_state.last_reward_update = timestamp::now_seconds();
    }
    
    public entry fun withdraw_vault_rewards(
        vault_owner: &signer
    ) acquires VaultState {
        let owner_addr = signer::address_of(vault_owner);
        assert!(exists<VaultState>(owner_addr), E_NOT_INITIALIZED);
        
        let vault_state = borrow_global_mut<VaultState>(owner_addr);
        vault_state.total_rewards_claimed = vault_state.total_rewards_claimed + 1000;
    }
    
    public fun get_user_position(user_addr: address): (u64, u64, u64) acquires UserPosition {
        if (!exists<UserPosition>(user_addr)) {
            return (0, 0, 0)
        };
        
        let position = borrow_global<UserPosition>(user_addr);
        (
            position.deposited_amount,
            position.last_deposit_time,
            position.reward_share
        )
    }
    
    public fun get_vault_state(vault_owner: address): (u64, u64, u64) acquires VaultState {
        assert!(exists<VaultState>(vault_owner), E_NOT_INITIALIZED);
        
        let state = borrow_global<VaultState>(vault_owner);
        (
            state.total_deposited,
            state.total_rewards_claimed,
            state.last_reward_update
        )
    }
    
    public fun calculate_reward_share(
        user_addr: address,
        vault_owner: address,
        total_vault_rewards: u64
    ): u64 acquires UserPosition, VaultState {
        if (!exists<UserPosition>(user_addr)) {
            return 0
        };
        
        let user_position = borrow_global<UserPosition>(user_addr);
        let vault_state = borrow_global<VaultState>(vault_owner);
        
        if (vault_state.total_deposited == 0) {
            return 0
        };
        
        (user_position.deposited_amount * total_vault_rewards) / vault_state.total_deposited
    }
}