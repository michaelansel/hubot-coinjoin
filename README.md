# hubot-coinjoin

Have hubot coordinate a coinjoin transaction. Currently only supports defcoin and requires you to manually send the transaction to the network. Fees are distributed evenly amongst all participants.

See [`src/coinjoin.coffee`](src/coinjoin.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-coinjoin --save`

Then add **hubot-coinjoin** to your `external-scripts.json`:

```json
[
  "hubot-coinjoin"
]
```

## Performing a coinjoin

- Assemble a group of people
- Agree on a coinjoin amount
  - `hubot coinjoin amount 1234`
- Each person:
  - Create a new address ("coinjoin-source")
  - Send coinjoin amount ("1234") to coinjoin-source (change can go wherever you want)
  - Wait for at least one confirmation
  - Find the resulting coin by opening debug window in defcoin-qt and running "listunspent"
```json
{
"txid" : "8cc93fa8e55d04c4a50ac30a7a4250adfe764fd39c4f04d36185114023a95ab4",
"vout" : 1,
"address" : "DQaveoMuZRGAaAfinvH4ywmag2FUpZMTMx",
"account" : "coinjoin-source",
"scriptPubKey" : "76a914d54cf3937cd75978d855b1956c44aa2e41f6314288ac",
"amount" : 1.00000000,
"confirmations" : 2
},
```
  - Make absolutely sure the coin amount matches the coinjoin amount! Any extra coin will be donated to the block miner as fees
  - Share txid and vout with the group
    - `hubot coinjoin add input 8cc93fa8e55d04c4a50ac30a7a4250adfe764fd39c4f04d36185114023a95ab4 1`
  - Create a new address with a unique name (only use this once!) e.g. "coinjoin-output (2015-11-11.01)"
  - Share destination address with the group
    - `hubot coinjoin add output DHHkj2vFk1okWiScuPh8KkPnxnULjMmyej`
- Build the transaction
  - `hubot coinjoin build`
  - `hubot-coinjoin` assembles all sources and destinations into a single transaction
- Each person, **validate** and then sign the transaction
  - 'decoderawtransaction <txdata>' in debug window and **confirm your address is receiving the correct amount**
  - 'signrawtransaction <txdata>' (might need to unlock your wallet with 'walletpassphrase <pass> <time>')
  - `hubot coinjoin add signature 0100000002b74...`
- When all signatures have been entered, coinjoin bot will return the final fully-signed transaction
  - one person then needs to submit the transaction to the network with 'sendrawtransaction <txdata>'
- Look under 'Inputs' on the Send tab to see your newly anonymized coin! Remember, you are only as anonymous as your communication medium and the more coinjoins you perform with different people, the more anonymous your coin will become!

## Sample Interaction

```
user1>> hubot coinjoin reset
hubot>> Ready to perform a coinjoin!
hubot>> 1. Set the amount of the coinjoin with 'hubot coinjoin amount <# of uDFC>'.
hubot>> 2. Each person: add your desired input (from 'listunspent') using 'hubot coinjoin add input <TxID> <vout>'.
hubot>> 3. Each person: add your desired output with 'hubot coinjoin add output <dfcAddress>'.
hubot>> 4. Assemble the transaction! 'hubot coinjoin build'

user1>> hubot coinjoin amount 1000000
hubot>> Coinjoin amount set to 1000000 uDFC

user1>> hubot coinjoin add input 2c2722b3c2ecf13c5196cf96e586ae6d9b859d23e157ddc71c7879599fa5e6f3 1
hubot>> user1: Input transaction added successfully
user2>> hubot coinjoin add input 049ab035752a5d4780fca507c1a1b6d9c3b1727279aa57ef5f2d444dd2652f93 0
hubot>> user2: Input transaction added successfully

user1>> hubot coinjoin add output DGQkePf8wQ94WGRfnE3yvcVfFr49VrEdoE
hubot>> user1: Output address added successfully
user2>> hubot coinjoin add output DQquGGfA8FFuhGH7KGkHmWQHnv2Mqf2K4e
hubot>> user2: Output address added successfully

user1>> hubot coinjoin build
hubot>> Transaction assembled. Minus fees, everyone will receive 1000000 uDFC. If you agree, please validate and sign the following transaction:
hubot>> 0100000002932f65d24d442d5fef57aa797272b1c3d9b6a1c107a5fc80475d2a7535b09a040100000000ffffffff695a3af9ffacb78d5d3e6dd37398f53d64def88b8da67cc9a9bf5743fa375f700100000000ffffffff0200e1f505000000001976a914cc590884f24bf6df48389f3e59755670c5b9176388ac00e1f505000000001976a91479c90aa51632c525f5e69f343559bfab8e82bd7588ac00000000
hubot>> Using the debug window, run 'decoderawtransaction <txdata>' and validate that you are getting the expected amount of coin back. Then, run 'signrawtransaction <txdata>' to add your stamp of approval (you may need to unlock your wallet with 'walletpassphrase <password> <numSecond>'. Paste the result (no quotes) back in chat like so: 'hubot coinjoin add signature <txdata>'

user1>> hubot coinjoin show
hubot>>
Amount: 1000000 uDFC
Inputs:
  2c2722b3c2ecf13c5196cf96e586ae6d9b859d23e157ddc71c7879599fa5e6f3:1 (=1000000 uDFC) by michaelansel
  049ab035752a5d4780fca507c1a1b6d9c3b1727279aa57ef5f2d444dd2652f93:0 (=29000000 uDFC) by michaelansel
Outputs:
  DGQkePf8wQ94WGRfnE3yvcVfFr49VrEdoE
  DQquGGfA8FFuhGH7KGkHmWQHnv2Mqf2K4e

user1>> hubot coinjoin add signature 0100000002f3e6a59f5979781cc7dd57e1239d859b6dae86e596cf96513cf1ecc2b322272c010000006a47304402204bd0a2b8720a958c9c712a643566acd80cb51ac79f2a784bcf94cadc4764554102201efc52b00e6c7e1d5118e86e4e1532d002533f8444c36d9e5599d0d08ba5605f012103f77cc4e76a425abc51d85540f0287e3ffa2a555d66d34876811f15ba8d822e0cffffffff932f65d24d442d5fef57aa797272b1c3d9b6a1c107a5fc80475d2a7535b09a040000000000ffffffff0200e1f505000000001976a9147b9f6e9f666ce481fa81f0eb7abd7bb762ffd3b888ac00e1f505000000001976a914d8220829c0e67513fe7a86c2e9b9b8645581a33b88ac00000000
hubot>> 1 signatures remaining
user2>> hubot coinjoin add signature 0100000002f3e6a59f5979781cc7dd57e1239d859b6dae86e596cf96513cf1ecc2b322272c010000006a47304402204bd0a2b8720a958c9c712a643566acd80cb51ac79f2a784bcf94cadc4764554102201efc52b00e6c7e1d5118e86e4e1532d002533f8444c36d9e5599d0d08ba5605f012103f77cc4e76a425abc51d85540f0287e3ffa2a555d66d34876811f15ba8d822e0cffffffff932f65d24d442d5fef57aa797272b1c3d9b6a1c107a5fc80475d2a7535b09a04000000006c493046022100974a5839ec3dc4e25826f90a2282b98135f42ce1729386c9ad449db88a306a0f022100e9cf3d3d72da9125f3686f0bc1bd7e92cac2696ccfdc0bf4b97e59cb7c26db52012103dd93ab8957c17af03880f65269bfba025c2310549b2c264222bcd5d6e1fa9523ffffffff0200e1f505000000001976a9147b9f6e9f666ce481fa81f0eb7abd7bb762ffd3b888ac00e1f505000000001976a914d8220829c0e67513fe7a86c2e9b9b8645581a33b88ac00000000
hubot>> All done! Finished transaction: 0100000002932f65d24d442d5fef57aa797272b1c3d9b6a1c107a5fc80475d2a7535b09a04010000006b483045022100cd74880dab9b42b9751b22830c600689d5fb9f79775e7728714d54df6f8e6df3022044d022d14eb2db3411b8c12ed7ac7d0aae999f3bee944933cd487bcbac3cb29401210325fad871baa49aad1b6d7e59279299febad8e59c8b9a8df92c9a75ea74669a8dffffffff695a3af9ffacb78d5d3e6dd37398f53d64def88b8da67cc9a9bf5743fa375f70010000006a47304402206bb3f7cea3fd619f53e704ce992978d60a170860c8972df8587821d80a537703022049d13149817c666edfa476f7add66e83f91cac131b0ccce64947c6fd068651fc012103f77cc4e76a425abc51d85540f0287e3ffa2a555d66d34876811f15ba8d822e0cffffffff0200e1f505000000001976a914cc590884f24bf6df48389f3e59755670c5b9176388ac00e1f505000000001976a91479c90aa51632c525f5e69f343559bfab8e82bd7588ac00000000
```
