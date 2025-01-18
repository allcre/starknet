use starknet::ContractAddress;

#[starknet::interface]
trait IAuraToken {
    fn initialize(ref self: TContractState, owner: ContractAddress);
    fn mint_aura(ref self: TContractState, to: ContractAddress, amount: u256);
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
}

#[starknet::contract]
mod AuraToken {
    use openzeppelin::token::erc20::ERC20;
    use starknet::ContractAddress;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: ERC20, storage: erc20, event: ERC20Event);
    component!(path: OwnershipComponent, storage: ownership, event: OwnershipEvent);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20::ERC20Component<ContractState>;
    #[abi(embed_v0)]
    impl OwnershipImpl = OwnableComponent::OwnableImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20::Storage,
        #[substorage(v0)]
        ownership: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20::Event,
        #[flat]
        OwnershipEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let name = 'Aura Token';
        let symbol = 'AURA';
        self.erc20.initializer(name, symbol);
    }

    #[external(v0)]
    impl AuraToken of super::IAuraToken {
        fn initialize(ref self: ContractState, owner: ContractAddress) {
            self.ownership.initializer(owner);
        }

        fn mint_aura(ref self: ContractState, to: ContractAddress, amount: u256) {
            self.ownership.assert_only_owner();
            self.erc20._mint(to, amount);
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }
    }
}
