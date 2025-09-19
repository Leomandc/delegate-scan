import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.5.4/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Test delegate registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const block = chain.mineBlock([
            Tx.contractCall('delegate-tracking', 'register-delegate', 
                [
                    types.utf8('Impact Research Expert'),
                    types.utf8('Climate Change Mitigation')
                ], 
                deployer.address)
        ]);

        // Check if delegate registration returns an ID
        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Test credential issuance",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const alice = accounts.get('wallet_1')!;

        // First register a delegate
        const registerBlock = chain.mineBlock([
            Tx.contractCall('delegate-tracking', 'register-delegate', 
                [
                    types.utf8('Environmental Policy Advisor'),
                    types.utf8('Sustainable Development')
                ], 
                alice.address)
        ]);

        const delegateId = registerBlock.receipts[0].result.expectOk().asUint;

        // Then issue a credential
        const credentialBlock = chain.mineBlock([
            Tx.contractCall('delegate-tracking', 'issue-delegate-credential', 
                [
                    types.uint(delegateId),
                    types.utf8('Climate Impact Assessment'),
                    types.utf8('Verified expertise in carbon footprint analysis'),
                    types.uint(50)
                ], 
                deployer.address)
        ]);

        // Check if credential is issued successfully
        credentialBlock.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Test total delegate impact tracking",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const alice = accounts.get('wallet_1')!;

        // Register a delegate
        const registerBlock = chain.mineBlock([
            Tx.contractCall('delegate-tracking', 'register-delegate', 
                [
                    types.utf8('Sustainability Consultant'),
                    types.utf8('Renewable Energy')
                ], 
                alice.address)
        ]);

        const delegateId = registerBlock.receipts[0].result.expectOk().asUint;

        // Issue multiple credentials
        const credentialBlock = chain.mineBlock([
            Tx.contractCall('delegate-tracking', 'issue-delegate-credential', 
                [
                    types.uint(delegateId),
                    types.utf8('Renewable Energy Impact'),
                    types.utf8('Comprehensive solar energy assessment'),
                    types.uint(75)
                ], 
                deployer.address),
            Tx.contractCall('delegate-tracking', 'issue-delegate-credential', 
                [
                    types.uint(delegateId),
                    types.utf8('Wind Energy Verification'),
                    types.utf8('Advanced wind farm performance analysis'),
                    types.uint(100)
                ], 
                deployer.address)
        ]);

        // Retrieve total delegate impact
        const totalImpactCall = chain.callReadOnlyFn(
            'delegate-tracking', 
            'get-total-delegate-impact', 
            [], 
            deployer.address
        );

        // Impact should be 175 (75 + 100)
        totalImpactCall.result.expectUint(175);
    }
});