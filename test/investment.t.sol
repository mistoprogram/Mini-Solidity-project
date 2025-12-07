// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/investment.sol";

contract InvestmentPoolTest is Test {
    InvestmentPool public pool;
    address owner = address(1);
    address investor1 = address(2);
    address investor2 = address(3);

    function setUp() public {
        vm.prank(owner);
        pool = new InvestmentPool();
    }

    function testCreatePool() public {
        vm.prank(owner);
        uint poolId = pool.createPool(10 ether, 1);
        
        assertEq(poolId, 0);
        assertEq(pool.getPoolCount(), 1);
    }

    function testInvestment() public {
        vm.prank(owner);
        uint poolId = pool.createPool(10 ether, 1);

        vm.prank(investor1);
        vm.deal(investor1, 5 ether);
        pool.investIn{value: 5 ether}(poolId, 5 ether);

        assertEq(pool.getTotalPooledAmount(poolId), 5 ether);
    }

    function testClosePoolAfterDeadline() public {
        vm.prank(owner);
        uint poolId = pool.createPool(10 ether, 1);

        // Invest less than target (so pool doesn't auto-close)
        vm.prank(investor1);
        vm.deal(investor1, 5 ether);
        pool.investIn{value: 5 ether}(poolId, 5 ether);

        // Advance time past deadline
        vm.warp(block.timestamp + 2 days);

        vm.prank(owner);
        pool.closePool(poolId);

        assertEq(pool.getPoolStatus(poolId), "closed");
    }

    function testReturnDistribution() public {
        // Setup: Create pool with 10 ETH target
        vm.prank(owner);
        uint poolId = pool.createPool(10 ether, 1);

        // Investor1 invests 4 ETH (40%)
        vm.prank(investor1);
        vm.deal(investor1, 4 ether);
        pool.investIn{value: 4 ether}(poolId, 4 ether);

        // Investor2 invests 6 ETH (60%)
        // This will auto-close the pool since 4 + 6 = 10 (target reached)
        vm.prank(investor2);
        vm.deal(investor2, 6 ether);
        pool.investIn{value: 6 ether}(poolId, 6 ether);

        // Pool should be auto-closed now
        assertEq(pool.getPoolStatus(poolId), "closed");

        // Owner deposits 12 ETH returns (2 ETH profit)
        vm.prank(owner);
        vm.deal(owner, 12 ether);
        pool.receiveReturn{value: 12 ether}(poolId, 12 ether);

        // Pool should now be completed
        assertEq(pool.getPoolStatus(poolId), "completed");

        // Verify payouts are calculated correctly
        // Investor1: 4 ETH + (2 ETH * 40%) = 4 + 0.8 = 4.8 ETH
        uint payout1 = pool.getInvestorPayoutAmount(poolId, investor1);
        assertEq(payout1, 4800000000000000000); // 4.8 ETH

        // Investor2: 6 ETH + (2 ETH * 60%) = 6 + 1.2 = 7.2 ETH
        uint payout2 = pool.getInvestorPayoutAmount(poolId, investor2);
        assertEq(payout2, 7200000000000000000); // 7.2 ETH
    }

    function testWithdrawal() public {
        // Setup: Create and fund pool
        vm.prank(owner);
        uint poolId = pool.createPool(10 ether, 1);

        // Give investor1 exactly 10 ETH and invest it all
        vm.prank(investor1);
        vm.deal(investor1, 10 ether);
        pool.investIn{value: 10 ether}(poolId, 10 ether);

        // At this point investor1 has 0 ETH (sent all to contract)
        uint investor1BalanceAfterInvest = investor1.balance;
        assertEq(investor1BalanceAfterInvest, 0);

        // Pool is auto-closed, now owner deposits returns
        vm.prank(owner);
        vm.deal(owner, 12 ether);
        pool.receiveReturn{value: 12 ether}(poolId, 12 ether);

        // Investor1 checks their payout
        uint payout = pool.getInvestorPayoutAmount(poolId, investor1);
        assertEq(payout, 12 ether);

        // Get balance before withdrawal
        uint balanceBeforeWithdrawal = investor1.balance;

        // Investor1 withdraws
        vm.prank(investor1);
        pool.withdraw(poolId);

        // Get balance after withdrawal
        uint balanceAfterWithdrawal = investor1.balance;

        // Should have received 12 ETH
        assertEq(balanceAfterWithdrawal - balanceBeforeWithdrawal, 12 ether);

        // Verify investor has received the payout
        assertEq(balanceAfterWithdrawal, 12 ether);

        // Should not be able to withdraw twice
        vm.prank(investor1);
        vm.expectRevert("You already withdrawn");
        pool.withdraw(poolId);
    }

    function testCannotWithdrawBeforeCompletion() public {
        vm.prank(owner);
        uint poolId = pool.createPool(10 ether, 1);

        vm.prank(investor1);
        vm.deal(investor1, 5 ether);
        pool.investIn{value: 5 ether}(poolId, 5 ether);

        // Try to withdraw before pool is completed (should fail)
        vm.prank(investor1);
        vm.expectRevert("Pool status must be completed!");
        pool.withdraw(poolId);
    }

    function testMultipleInvestors() public {
        vm.prank(owner);
        uint poolId = pool.createPool(10 ether, 1);

        // 3 investors contribute equally
        address investor3 = address(4);

        vm.prank(investor1);
        vm.deal(investor1, 3.33 ether);
        pool.investIn{value: 3.33 ether}(poolId, 3.33 ether);

        vm.prank(investor2);
        vm.deal(investor2, 3.33 ether);
        pool.investIn{value: 3.33 ether}(poolId, 3.33 ether);

        vm.prank(investor3);
        vm.deal(investor3, 3.34 ether);
        pool.investIn{value: 3.34 ether}(poolId, 3.34 ether);

        // Pool should auto-close
        assertEq(pool.getPoolStatus(poolId), "closed");

        // Owner deposits returns
        vm.prank(owner);
        vm.deal(owner, 11 ether);
        pool.receiveReturn{value: 11 ether}(poolId, 11 ether);

        // All investors should have payouts
        uint payout1 = pool.getInvestorPayoutAmount(poolId, investor1);
        uint payout2 = pool.getInvestorPayoutAmount(poolId, investor2);
        uint payout3 = pool.getInvestorPayoutAmount(poolId, investor3);

        // Total should be 11 ETH
        assertEq(payout1 + payout2 + payout3, 11 ether);
    }
}