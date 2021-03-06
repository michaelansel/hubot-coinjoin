chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

{Coinjoin} = require '../src/coinjoin'

describe 'coinjoin', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/coinjoin')(@robot)

  it 'registers a respond listener', ->
    expect(@robot.respond).to.have.been.called

describe 'Coinjoin', ->
  it 'works end-to-end', (done) ->
    cj = new Coinjoin()
    expect(cj.setAmount(1000000)).to.equal(100000000)

    cj.addInput 'derp', '2c2722b3c2ecf13c5196cf96e586ae6d9b859d23e157ddc71c7879599fa5e6f3', 1, (resultA) ->
      cj.addInput 'derp', '049ab035752a5d4780fca507c1a1b6d9c3b1727279aa57ef5f2d444dd2652f93', 0, (resultB) ->
        process.nextTick ->
          expect(resultA).to.deep.equal([true, 'Input transaction added successfully (1000000 uDFC)'])
          expect(resultB).to.deep.equal([true, 'Input transaction added successfully, BUT the amount was wrong (29000000 uDFC != expected 1000000 uDFC)'])
          expect(cj.addOutput('DGQkePf8wQ94WGRfnE3yvcVfFr49VrEdoE')).to.deep.equal([true, 'Output address added successfully'])
          expect(cj.addOutput('DQquGGfA8FFuhGH7KGkHmWQHnv2Mqf2K4e')).to.deep.equal([true, 'Output address added successfully'])
          expect(cj.build()).to.deep.equal([true, {amount:100000000, txdata: '0100000002f3e6a59f5979781cc7dd57e1239d859b6dae86e596cf96513cf1ecc2b322272c0100000000ffffffff932f65d24d442d5fef57aa797272b1c3d9b6a1c107a5fc80475d2a7535b09a040000000000ffffffff0200e1f505000000001976a9147b9f6e9f666ce481fa81f0eb7abd7bb762ffd3b888ac00e1f505000000001976a914d8220829c0e67513fe7a86c2e9b9b8645581a33b88ac00000000'}])
          expect(cj.addSignature('0100000002f3e6a59f5979781cc7dd57e1239d859b6dae86e596cf96513cf1ecc2b322272c010000006a47304402204bd0a2b8720a958c9c712a643566acd80cb51ac79f2a784bcf94cadc4764554102201efc52b00e6c7e1d5118e86e4e1532d002533f8444c36d9e5599d0d08ba5605f012103f77cc4e76a425abc51d85540f0287e3ffa2a555d66d34876811f15ba8d822e0cffffffff932f65d24d442d5fef57aa797272b1c3d9b6a1c107a5fc80475d2a7535b09a040000000000ffffffff0200e1f505000000001976a9147b9f6e9f666ce481fa81f0eb7abd7bb762ffd3b888ac00e1f505000000001976a914d8220829c0e67513fe7a86c2e9b9b8645581a33b88ac00000000')).to.deep.equal([true, '1 signatures remaining'])
          expect(cj.addSignature('0100000002f3e6a59f5979781cc7dd57e1239d859b6dae86e596cf96513cf1ecc2b322272c010000006a47304402204bd0a2b8720a958c9c712a643566acd80cb51ac79f2a784bcf94cadc4764554102201efc52b00e6c7e1d5118e86e4e1532d002533f8444c36d9e5599d0d08ba5605f012103f77cc4e76a425abc51d85540f0287e3ffa2a555d66d34876811f15ba8d822e0cffffffff932f65d24d442d5fef57aa797272b1c3d9b6a1c107a5fc80475d2a7535b09a04000000006c493046022100974a5839ec3dc4e25826f90a2282b98135f42ce1729386c9ad449db88a306a0f022100e9cf3d3d72da9125f3686f0bc1bd7e92cac2696ccfdc0bf4b97e59cb7c26db52012103dd93ab8957c17af03880f65269bfba025c2310549b2c264222bcd5d6e1fa9523ffffffff0200e1f505000000001976a9147b9f6e9f666ce481fa81f0eb7abd7bb762ffd3b888ac00e1f505000000001976a914d8220829c0e67513fe7a86c2e9b9b8645581a33b88ac00000000')).to.deep.equal([true, 'All done! Finished transaction: 0100000002f3e6a59f5979781cc7dd57e1239d859b6dae86e596cf96513cf1ecc2b322272c010000006a47304402204bd0a2b8720a958c9c712a643566acd80cb51ac79f2a784bcf94cadc4764554102201efc52b00e6c7e1d5118e86e4e1532d002533f8444c36d9e5599d0d08ba5605f012103f77cc4e76a425abc51d85540f0287e3ffa2a555d66d34876811f15ba8d822e0cffffffff932f65d24d442d5fef57aa797272b1c3d9b6a1c107a5fc80475d2a7535b09a04000000006c493046022100974a5839ec3dc4e25826f90a2282b98135f42ce1729386c9ad449db88a306a0f022100e9cf3d3d72da9125f3686f0bc1bd7e92cac2696ccfdc0bf4b97e59cb7c26db52012103dd93ab8957c17af03880f65269bfba025c2310549b2c264222bcd5d6e1fa9523ffffffff0200e1f505000000001976a9147b9f6e9f666ce481fa81f0eb7abd7bb762ffd3b888ac00e1f505000000001976a914d8220829c0e67513fe7a86c2e9b9b8645581a33b88ac00000000'])

          done()
