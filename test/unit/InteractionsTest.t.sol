//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../../test/mocks/LinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract InteractionsTest is Test {
    /*Events*/
    event EnteredRaffle(address indexed player);
    CreateSubscription createsub;
    FundSubscription funded;
    AddConsumer addcon;
    HelperConfig helperConfig;
    Raffle raffle;
    LinkToken linktoken;

    address vrfCoordinator;
    uint256 deployerKey;
    uint64 subId;
    address link;
    address owner;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (, , vrfCoordinator, , subId, , link, deployerKey) = helperConfig
            .activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    ////////////////////////////////
    // CreateSubscription    //////
    ///////////////////////////////

    function testCreateSubscriptionIsGivingSubId() public {
        vm.prank(PLAYER);
        CreateSubscription createsub = new CreateSubscription();
        uint64 Id = createsub.createSubscription(
            vrfCoordinator,
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );
        assert(Id != 0 && Id != subId);
    }

    /////////////////////////////////
    // FundSubscription       //////
    ///////////////////////////////

    function testFundSubscriptionRevertsIfNotAValidSubscription() public {
        vm.prank(PLAYER);
        FundSubscription funded = new FundSubscription();
        vm.expectRevert();
        funded.fundSubscription(
            vrfCoordinator,
            0,
            link,
            0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
        );
    }

    function testFundSubscriptionWorks() public {
        vm.prank(PLAYER);

        CreateSubscription createsub = new CreateSubscription();
        uint64 Id = createsub.createSubscription(
            vrfCoordinator,
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );

        uint96 FUND_AMOUNT = 3 ether;
        VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(Id, FUND_AMOUNT);
    }

    ///////////////////////////
    // Add Consumer         //
    //////////////////////////

    function testAddConsumerRevertsIfNotAValidSubscription() public {
        vm.prank(PLAYER);

        AddConsumer addcon = new AddConsumer();
        vm.expectRevert();

        addcon.addConsumer(
            address(raffle),
            vrfCoordinator,
            0,
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );
    }

    function testAddConsumerWorks() public {
        vm.prank(PLAYER);

        CreateSubscription createsub = new CreateSubscription();
        uint64 Id = createsub.createSubscription(
            vrfCoordinator,
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );

        FundSubscription fundsub = new FundSubscription();
        fundsub.fundSubscription(
            vrfCoordinator,
            Id,
            link,
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );

        AddConsumer addcon = new AddConsumer();
        addcon.addConsumer(
            address(raffle),
            vrfCoordinator,
            Id,
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );
    }

    ////////////////////////////////
    // Deployer Raffle         ////
    //////////////////////////////

    function testDeployRaffleWorks() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (, , vrfCoordinator, , subId, , link, deployerKey) = helperConfig
            .activeNetworkConfig();
        assert(subId == 0);
    }
}
