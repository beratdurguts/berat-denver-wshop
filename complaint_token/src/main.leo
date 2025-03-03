import credits.aleo;
import token_registry.aleo;


program compliance_token_beratdrgt.aleo {

  const COMPLAINT_TOKEN_ID: field = 716190632346531412124863field; // Unique token identifier
  const ADMIN_ADDRESS: address = aleo1uw8e4nq0clpt9400sz0wdm64psjktqm28jq9c0qaxy7974v8rupqhu44sa; // Admin address with minting and issuing privileges
  const MAX_SUPPLY: u128 = 1_000_000_000_000_000u128; // Maximum supply of the token
  const BLOCKS_IN_A_DAY: u32 = 28_800u32; // Number of blocks per day for epoch-based calculations
  const MAX_SPEND_PER_DAY: u128 = 10_000_000_000u128; // Daily spending limit per user
  const MAX_U32: u32 = 4294967295u32; // Maximum value of a u32, used for transaction expiration

  
  record SpendLimit {
    owner: address,      
    amount_spent: u128, 
    epoch_spent: u32     
  }

  mapping has_minted: u8 => bool;
  
  
  mapping has_spend_limit: field => bool;


  async transition initialize() -> Future {
    assert_eq(self.caller, ADMIN_ADDRESS);

    let name: u128 = 71619063614564653278361413253u128; 
    let symbol: u128 = 71619063614564653278361413253u128; 
    let decimals: u8 = 6u8; 
    let max_supply: u128 = 10_000_000_000_000_000u128; 
    let external_authorization_required: bool = true;
    let external_authorization_party: address = self.address;

    // Register the token in the token registry
    let f0: Future = token_registry.aleo/register_token(
      COMPLAINT_TOKEN_ID,
      name,
      symbol,
      decimals,
      max_supply,
      external_authorization_required,
      external_authorization_party
    );

    return finalize_register_token(f0);
  }


  async function finalize_register_token(f0: Future) {
    f0.await();
  }


  async transition mint_private() -> (token_registry.aleo/Token, Future) {
    assert_eq(self.caller, ADMIN_ADDRESS);
    
    // Mint private tokens to the admin
    let mint_output: (token_registry.aleo/Token, Future) = token_registry.aleo/mint_private(
      COMPLAINT_TOKEN_ID,
      ADMIN_ADDRESS,
      MAX_SUPPLY,
      true,
      MAX_U32
    );

    return (mint_output.0, finalize_mint_private(mint_output.1));
  }


  async function finalize_mint_private(f0: Future) {
    f0.await();

    let has_already_minted: bool = has_minted.contains(0u8);
    assert(!has_already_minted); // Ensure tokens are minted only once
    has_minted.set(0u8, true);
  }


  transition issue_limit(
    owner: address
  ) -> SpendLimit {
    assert_eq(self.caller, ADMIN_ADDRESS);

    // Create a new spend limit record for the user
    return SpendLimit {
      owner: owner,
      amount_spent: 0u128,
      epoch_spent: 0u32
    };
  }

  async transition transfer_private(
    input_token: token_registry.aleo/Token, // The input token record to be spent
    spend_limit: SpendLimit, // The user's spend limit record
    amount: u128, // Amount to transfer
    recipient: address, // Recipient address
    public epoch: u32 // Current epoch
  ) -> (SpendLimit, token_registry.aleo/Token, token_registry.aleo/Token, token_registry.aleo/Token, Future) {
    
    // Determine the updated amount spent based on the epoch
    let updated_amount_spent: u128 = spend_limit.epoch_spent < epoch 
        ? amount // Reset the spend amount if in a new epoch
        : amount + spend_limit.amount_spent; // Otherwise, accumulate the spend amount
    
    // Ensure the updated spend amount does not exceed the daily limit
    assert(updated_amount_spent <= MAX_SPEND_PER_DAY);

    // Create the updated spend limit record
    let updated_spend_limit: SpendLimit = SpendLimit {
      owner: spend_limit.owner,
      amount_spent: updated_amount_spent,
      epoch_spent: epoch
    };

    let prehook_output: (token_registry.aleo/Token, token_registry.aleo/Token, Future) = token_registry.aleo/prehook_private(
      input_token,
      amount,
      MAX_U32
    );

    let transfer_output: (token_registry.aleo/Token, token_registry.aleo/Token, Future) = token_registry.aleo/transfer_private(
      recipient,
      amount,
      prehook_output.1
    );

    return (
      updated_spend_limit, // The updated spend limit record
      prehook_output.0,    // Remaining balance from authorization
      transfer_output.0,   // Remaining balance from transfer (should be 0)
      transfer_output.1,   // The token record sent to the recipient
      finalize_transfer_private(prehook_output.2, transfer_output.2, epoch) // Await the finalization process
    );
  }

  async function finalize_transfer_private(
    f0: Future, // Future from prehook_private
    f1: Future, // Future from transfer_private
    epoch: u32
  ) {
    f0.await();
    f1.await();

    let current_epoch: u32 = block.height % BLOCKS_IN_A_DAY;
    assert_eq(epoch, current_epoch);
  }


}