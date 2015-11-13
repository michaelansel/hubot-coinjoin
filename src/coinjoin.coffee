# Description
#   Have hubot coordinate a defcoin coinjoin transaction
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
#   hubot coinjoin reset - Clear all the coinjoin state
#   hubot coinjoin amount <amount in uDFC> - Set the coinjoin amount in WHOLE uDFC (1 DFC = 1e6 uDFC), no decimals
#   hubot coinjoin add input <transaction> <vout> - Add a previous transaction output ("some coin") to the coinjoin
#   hubot coinjoin add output <defcoin address> - Add your output address to the coinjoin
#   hubot coinjoin show - Dump the current state of the coinjoin transaction
#   hubot coinjoin build - Assemble a transaction out of the provided inputs/outputs
#   hubot coinjoin add signature - Add your version of the partially signed transaction
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Michael Ansel <mansel@box.com>

bitcoin = require 'bitcoinjs-lib'
request = require 'request'

# Monkeypatch this in
bitcoin.networks.defcoin =
  messagePrefix: '\x19defcoin Signed Message:\n'
  bip32:
    public: 0x019da462 # copied from litecoin
    private: 0x019d9cfe # copied from litecoin
  wif: 0x9e
  pubKeyHash: 0x1e
  scriptHash: 0x05
  dustThreshold: 0


#DEFAULT_TRANSACTION_FEE=0.001 # Default on the defcoin network
DEFAULT_TRANSACTION_FEE=0 # Great for testing

USE_ASSMEOW=true

if USE_ASSMEOW?
  getTxOutputAmount = (txid, vout, cb) ->
    request "http://defcoin.assmeow.org/rawtx/#{txid}", (error, response, body) ->
      if not error and response.statusCode is 200
        try
          # Super lazy parsing (assume all decimal digits always exist)
          cb null, parseInt(JSON.parse(body).out[vout].value.replace(/[.]/,'').replace(/^0+/,''))
        catch error
          cb error, null
      else
        cb error, null
else
  getTxOutputAmount = (txid, vout, cb) ->
    cb 'Transaction lookups disabled', null

class Coinjoin
  constructor: ->
    @inputs = []
    @outputs = []
    @amount = null
    @tx = null

  addInput: (name, txid, vout, cb) ->
    getTxOutputAmount txid, vout, (err, amount) =>
      @inputs.push
        txid: txid
        vout: vout
        name: name
        amount: amount

      err = "Coinjoin amount not set" unless err or @amount
      if err
        cb [true, "Input transaction added successfully (unable to verify amount: #{err})"]
      else
        if amount is @amount
          cb [true, "Input transaction added successfully (#{amount/100} uDFC)"]
        else
          cb [true, "Input transaction added successfully, BUT the amount was wrong (#{amount/100} uDFC != expected #{@amount/100} uDFC)"]

  addOutput: (address) ->
    @outputs.push
      address: address
    [true, "Output address added successfully"]

  addSignature: (partialTx) ->
    partialTxB = bitcoin.TransactionBuilder.fromTransaction( bitcoin.Transaction.fromHex(partialTx) )
    return [false, "WTF? This transaction doesn't match the current coinjoin!"] unless @tx.inputs.length is partialTxB.inputs.length

    # Integrate signatures we don't already have
    @tx.inputs = @tx.inputs.map (input, idx) ->
      if not input.signatures? and partialTxB.inputs[idx].signatures?
        partialTxB.inputs[idx]
      else
        input

    sigsNeeded = @tx.inputs.length - @countSignatures()
    if sigsNeeded > 0
      [true, "#{sigsNeeded} signatures remaining"]
    else
      [true, "All done! Finished transaction: #{@tx.build().toHex()}"]

  build: ->
    return [false, "Missing amount of transaction"] unless @amount?

    # Distribute the fee evenly across participants and round down
    amountPerOutput = Math.floor( (@outputs.length * @amount - @getFee())/@outputs.length )

    # Create a NEW TransactionBuilder every time we build
    @tx = new bitcoin.TransactionBuilder(bitcoin.networks.defcoin)

    try
      @tx.addInput(input.txid, input.vout) for input in @inputs
      @tx.addOutput(output.address, amountPerOutput) for output in @outputs
    catch error
      return [false, "Error when assembling transaction: #{error}"]

    [true,
      amount: amountPerOutput
      txdata: @tx.buildIncomplete().toHex()
    ]

  countSignatures: ->
    count = 0
    for input in @tx.inputs
      count = count + 1 if input.signatures?
    count

  dump: ->
    {
      amount: @amount
      inputs: @inputs
      outputs: @outputs
    }

  getFee: ->
    # Hardcoded fee for now
    DEFAULT_TRANSACTION_FEE

  setAmount: (amount) ->
    # Store in satoshis (input is uDFC)
    @amount = amount * 100

module.exports = (robot) ->
  # Map of room to coinjoin state
  activeCoinjoins = {}

  getCj = (res) ->
    activeCoinjoins[res.room] ?= new Coinjoin

  robot.respond /coinjoin amount ([0-9]+)$/i, (res) ->
    cj = getCj res
    cj.setAmount parseInt(res.match[1])
    res.reply "Coinjoin amount set to #{cj.amount/100} uDFC"

  robot.respond /coinjoin add input (.+) ([0-9]+)$/i, (res) ->
    cj = getCj res
    cj.addInput res.message.user.name, res.match[1], parseInt(res.match[2]), (result) ->
      if result[0]
        res.reply result[1]
      else
        res.reply "Unable to add input: #{result[1]}"

  robot.respond /coinjoin add output (.+)$/i, (res) ->
    cj = getCj res
    result = cj.addOutput res.match[1]
    if result[0]
      res.reply result[1]
    else
      res.reply "Unable to add output: #{result[1]}"

  robot.respond /coinjoin add signature (.+)$/i, (res) ->
    cj = getCj res
    result = cj.addSignature res.match[1]
    if result[0]
      res.reply result[1]
    else
      res.reply "Unable to add signature: #{result[1]}"

  robot.respond /coinjoin build$/i, (res) ->
    cj = getCj res
    result = cj.build()
    if result[0]
      res.reply "Transaction assembled. Minus fees, everyone will receive #{result[1].amount/100} uDFC. If you agree, please validate and sign the following transaction:"
      res.reply result[1].txdata
      res.reply "Using the debug window, run 'decoderawtransaction <txdata>' and validate that you are getting the expected amount of coin back. Then, run 'signrawtransaction <txdata>' to add your stamp of approval (you may need to unlock your wallet with 'walletpassphrase <password> <numSecond>'. Paste the result (no quotes) back in chat like so: '#{robot.name} coinjoin add signature <txdata>'"
    else
      res.reply "Unable to assemble the transaction: #{result[1]}"

  robot.respond /coinjoin reset$/i, (res) ->
    activeCoinjoins[res.room] = new Coinjoin
    res.reply 'Ready to perform a coinjoin!'
    res.reply "1. Set the amount of the coinjoin with '#{robot.name} coinjoin amount <# of uDFC>'."
    res.reply "2. Each person: add your desired input (from 'listunspent') using '#{robot.name} coinjoin add input <TxID> <vout>'."
    res.reply "3. Each person: add your desired output with '#{robot.name} coinjoin add output <dfcAddress>'."
    res.reply "4. Assemble the transaction! '#{robot.name} coinjoin build'"

  robot.respond /coinjoin show$/i, (res) ->
    cj = getCj res
    cjData = cj.dump()

    res.send "Amount: #{cj.amount/100} uDFC"
    res.send 'Inputs:'
    if cjData.inputs.length > 0
      res.send "  #{input.txid}:#{input.vout} (=#{input.amount/100} uDFC) by #{input.name}" for input in cjData.inputs
    else
      res.send '  None'

    res.send 'Outputs:'
    if cjData.outputs.length > 0
      res.send "  #{output.address}" for output in cjData.outputs
    else
      res.send '  None'

module.exports.Coinjoin = Coinjoin
