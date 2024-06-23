use aiken/dict
use aiken/hash.{Blake2b_224, Hash, sha2_256}
use aiken/interval.{Finite, Interval, IntervalBound}
use aiken/list.{any}
use aiken/time.{PosixTime}
use aiken/transaction.{
  NoDatum, Output, OutputReference, ScriptContext, Spend, Transaction,
  TransactionId,
}
use aiken/transaction/credential.{VerificationKey, from_verification_key}
use aiken/transaction/value.{from_lovelace, lovelace_of, to_minted_value, zero}

type HTLCDatum {
  secret_hash: ByteArray,
  timeout: PosixTime,
  owner: Hash<Blake2b_224, VerificationKey>,
}

type HTLCRedeemer {
  Claim(ByteArray)
  Refund
}

// Function to create fee value
fn fee_value() -> Int {
  1000000
}

// Check if the required fee has been paid
fn fee_paid(
  ctx: ScriptContext,
  team_address: Hash<Blake2b_224, VerificationKey>,
  required_fee: Int,
) -> Bool {
  any(
    ctx.transaction.outputs,
    fn(output: Output) {
      from_verification_key(team_address) == output.address && lovelace_of(
        output.value,
      ) >= required_fee
    },
  )
}

// Check if the transaction is signed by the owner
fn signed_by_owner(
  ctx: ScriptContext,
  owner: Hash<Blake2b_224, VerificationKey>,
) -> Bool {
  any(
    ctx.transaction.extra_signatories,
    fn(sig: Hash<Blake2b_224, VerificationKey>) { sig == owner },
  )
}

// Check if the deadline has passed
fn deadline_passed(timeout: PosixTime, current_time: PosixTime) -> Bool {
  current_time > timeout
}

// Get the current time from the ScriptContext
fn get_current_time(ctx: ScriptContext) -> PosixTime {
  let validity_range = ctx.transaction.validity_range
  when validity_range.lower_bound is {
    IntervalBound { bound_type: Finite(lower), is_inclusive: _ } -> lower
    _ -> 0
  }
}

// Validator
validator(team_address: Hash<Blake2b_224, VerificationKey>) {
  fn spend(datum: HTLCDatum, redeemer: HTLCRedeemer, ctx: ScriptContext) -> Bool {
    let current_time = get_current_time(ctx)
    when redeemer is {
      Claim(secret) ->
        sha2_256(secret) == datum.secret_hash && !deadline_passed(
          datum.timeout,
          current_time,
        ) && fee_paid(ctx, team_address, fee_value())
      Refund ->
        signed_by_owner(ctx, datum.owner) && deadline_passed(
          datum.timeout,
          current_time,
        ) && fee_paid(ctx, team_address, fee_value())
    }
  }
}

// Tests
test deadline_passed_test() {
  let timeout = 1000
  let current_time = 1500
  deadline_passed(timeout, current_time)
}

test deadline_not_passed_test() {
  let timeout = 2000
  let current_time = 1500
  !deadline_passed(timeout, current_time)
}

test fee_paid_test() {
  let team_address = #"00000000000000000000000000000000000000000000000000000000"
  let fee = fee_value()
  let outputs =
    [
      Output {
        address: from_verification_key(team_address),
        value: from_lovelace(fee),
        datum: NoDatum,
        reference_script: None,
      },
    ]
  let ctx =
    ScriptContext {
      transaction: Transaction {
        inputs: [],
        reference_inputs: [],
        outputs,
        fee: from_lovelace(0),
        mint: to_minted_value(zero()),
        certificates: [],
        withdrawals: dict.new(),
        validity_range: interval.everything(),
        extra_signatories: [],
        redeemers: dict.new(),
        datums: dict.new(),
        id: TransactionId {
          hash: #"0000000000000000000000000000000000000000000000000000000000000000",
        },
      },
      purpose: Spend(
        OutputReference {
          transaction_id: TransactionId {
            hash: #"0000000000000000000000000000000000000000000000000000000000000000",
          },
          output_index: 0,
        },
      ),
    }
  fee_paid(ctx, team_address, fee)
}

test fee_not_paid_test() {
  let team_address = #"00000000000000000000000000000000000000000000000000000000"
  let fee = fee_value() - 1
  let outputs =
    [
      Output {
        address: from_verification_key(team_address),
        value: from_lovelace(fee),
        datum: NoDatum,
        reference_script: None,
      },
    ]
  let ctx =
    ScriptContext {
      transaction: Transaction {
        inputs: [],
        reference_inputs: [],
        outputs,
        fee: from_lovelace(0),
        mint: to_minted_value(zero()),
        certificates: [],
        withdrawals: dict.new(),
        validity_range: interval.everything(),
        extra_signatories: [],
        redeemers: dict.new(),
        datums: dict.new(),
        id: TransactionId {
          hash: #"0000000000000000000000000000000000000000000000000000000000000000",
        },
      },
      purpose: Spend(
        OutputReference {
          transaction_id: TransactionId {
            hash: #"0000000000000000000000000000000000000000000000000000000000000000",
          },
          output_index: 0,
        },
      ),
    }
  !fee_paid(ctx, team_address, fee_value())
}

test signed_by_owner_test() {
  let owner = #"00000000000000000000000000000000000000000000000000000000"
  let ctx =
    ScriptContext {
      transaction: Transaction {
        inputs: [],
        reference_inputs: [],
        outputs: [],
        fee: from_lovelace(0),
        mint: to_minted_value(zero()),
        certificates: [],
        withdrawals: dict.new(),
        validity_range: interval.everything(),
        extra_signatories: [owner],
        redeemers: dict.new(),
        datums: dict.new(),
        id: TransactionId {
          hash: #"0000000000000000000000000000000000000000000000000000000000000000",
        },
      },
      purpose: Spend(
        OutputReference {
          transaction_id: TransactionId {
            hash: #"0000000000000000000000000000000000000000000000000000000000000000",
          },
          output_index: 0,
        },
      ),
    }
  signed_by_owner(ctx, owner)
}

test not_signed_by_owner_test() {
  let owner = #"00000000000000000000000000000000000000000000000000000000"
  let other_signer =
    #"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
  let ctx =
    ScriptContext {
      transaction: Transaction {
        inputs: [],
        reference_inputs: [],
        outputs: [],
        fee: from_lovelace(0),
        mint: to_minted_value(zero()),
        certificates: [],
        withdrawals: dict.new(),
        validity_range: interval.everything(),
        extra_signatories: [other_signer],
        redeemers: dict.new(),
        datums: dict.new(),
        id: TransactionId {
          hash: #"0000000000000000000000000000000000000000000000000000000000000000",
        },
      },
      purpose: Spend(
        OutputReference {
          transaction_id: TransactionId {
            hash: #"0000000000000000000000000000000000000000000000000000000000000000",
          },
          output_index: 0,
        },
      ),
    }
  !signed_by_owner(ctx, owner)
}
