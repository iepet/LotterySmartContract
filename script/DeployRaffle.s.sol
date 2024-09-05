//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription, FundSubscription,AddConsumer} from "./Interactions.s.sol";


contract DeployRaffle is Script {
    function run() external  {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // if in local we deploy mocks then we get local config
        // if sepolia, then we get sepolia tesnet config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();


        if (config.subscriptionId ==0){
            // In order for the vrf to work, we need a subscription id 
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId,config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator, config.account);
            
            //Fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator,config.subscriptionId, config.link, config.account);

        }
        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle),config.vrfCoordinator,config.subscriptionId, config.account);

        return (raffle,helperConfig);

    }

}
