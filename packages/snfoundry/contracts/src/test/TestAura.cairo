use contracts::Aura::{IAuraTokenDispatcher, IAuraTokenDispatcherTrait};
use snforge_std::{ContractClassTrait, DeclareResultTrait, cheat_caller_address, declare};
use starknet::{ContractAddress, contract_address_const};

// Test owner address
fn OWNER() -> ContractAddress {
    contract_address_const::<0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918>()
}

// Test user address
fn USER() -> ContractAddress {
    contract_address_const::<0x03dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5919>()
}

fn deploy_aura_token() -> ContractAddress {
    let contract_class = declare("AuraToken").unwrap().contract_class();
    let mut calldata = array![];
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_aura_token_initialization() {
    // Deploy contract
    let contract_address = deploy_aura_token();
    let dispatcher = IAuraTokenDispatcher { contract_address };

    // Initialize with owner
    dispatcher.initialize(OWNER());

    // Check initial balance is zero
    let balance = dispatcher.balance_of(OWNER());
    assert(balance == 0, 'Initial balance should be 0');
}

#[test]
fn test_mint_aura() {
    // Deploy and initialize
    let contract_address = deploy_aura_token();
    let dispatcher = IAuraTokenDispatcher { contract_address };
    dispatcher.initialize(OWNER());

    // Set caller as owner for minting
    cheat_caller_address(contract_address, OWNER(), CheatSpan::TargetCalls(1));

    // Mint tokens to user
    let mint_amount: u256 = 1000;
    dispatcher.mint_aura(USER(), mint_amount);

    // Check user balance
    let balance = dispatcher.balance_of(USER());
    assert(balance == mint_amount, 'Mint amount incorrect');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_mint_aura_unauthorized() {
    // Deploy and initialize
    let contract_address = deploy_aura_token();
    let dispatcher = IAuraTokenDispatcher { contract_address };
    dispatcher.initialize(OWNER());

    // Try to mint as non-owner (should fail)
    cheat_caller_address(contract_address, USER(), CheatSpan::TargetCalls(1));

    let mint_amount: u256 = 1000;
    dispatcher.mint_aura(USER(), mint_amount);
}

#[test]
fn test_multiple_balances() {
    // Deploy and initialize
    let contract_address = deploy_aura_token();
    let dispatcher = IAuraTokenDispatcher { contract_address };
    dispatcher.initialize(OWNER());

    // Mint to owner and user
    cheat_caller_address(contract_address, OWNER(), CheatSpan::TargetCalls(2));

    let owner_amount: u256 = 500;
    let user_amount: u256 = 1000;

    dispatcher.mint_aura(OWNER(), owner_amount);
    dispatcher.mint_aura(USER(), user_amount);

    // Check both balances
    let owner_balance = dispatcher.balance_of(OWNER());
    let user_balance = dispatcher.balance_of(USER());

    assert(owner_balance == owner_amount, 'Owner balance incorrect');
    assert(user_balance == user_amount, 'User balance incorrect');
}
