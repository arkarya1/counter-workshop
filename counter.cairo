#[starknet::interface]
pub trait ICounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T);
}

#[starknet::contract]
pub mod counter_contract {
    use starknet::event::EventEmitter;
    use super::ICounter;
    use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        counter : u32,
        kill_switch: IKillSwitchDispatcher,
    }
    #[constructor]
    fn constructor(ref self: ContractState, initial_value: u32, kill_switch_address: ContractAddress) {
        self.counter.write(initial_value);
        let dispatcher = IKillSwitchDispatcher { contract_address: kill_switch_address };
        self.kill_switch.write(dispatcher);
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        value : u32,
    }

    #[abi(embed_v0)]
    impl CounterImpl of ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            let kill_switch = self.kill_switch.read();
            assert!(!kill_switch.is_active(),"Kill Switch is active");
            if !kill_switch.is_active() {
                self.counter.write(self.counter.read() + 1);
                self.emit(CounterIncreased { value: self.counter.read() });
            }
        }
    }
}