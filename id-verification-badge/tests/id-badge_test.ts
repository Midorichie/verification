import { Clarinet, Tx, Chain, Account } from "clarinet";

Clarinet.test({
  name: "Only verifier can verify identity",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let verifier = accounts.get("deployer")!;
    let user = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("id-badge", "verify-identity", [`'${user.address}`], verifier.address),
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
  },
});
