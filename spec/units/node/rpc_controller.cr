# Copyright © 2017-2018 The SushiChain Core developers
#
# See the LICENSE file at the top-level directory of this distribution
# for licensing information.
#
# Unless otherwise agreed in a custom licensing agreement with the SushiChain Core developers,
# no part of this software, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in the
# LICENSE file.
#
# Removal or modification of this copyright notice is prohibited.

require "./../../spec_helper"
require "./../utils"

include Sushi::Core
include Units::Utils
include Sushi::Core::Controllers
include Sushi::Core::Keys

describe RPCController do
  describe "#exec_internal_post" do
    describe "#create_unsigned_transaction" do
      it "should return the transaction as json when valid" do
        with_factory do |block_factory, transaction_factory|
          senders = [a_sender(transaction_factory.sender_wallet, 1000_i64)]
          recipients = [a_recipient(transaction_factory.recipient_wallet, 10_i64)]

          payload = {
            call:       "create_unsigned_transaction",
            action:     "send",
            senders:    senders,
            recipients: recipients,
            message:    "",
            token:      TOKEN_DEFAULT,
          }.to_json

          json = JSON.parse(payload)

          with_rpc_exec_internal_post(block_factory.rpc, json) do |result|
            transaction = Transaction.from_json(result)
            transaction.action.should eq("send")
            transaction.prev_hash.should eq("0")
            transaction.message.should eq("")
            transaction.sign_r.should eq("0")
            transaction.sign_s.should eq("0")
            transaction.senders.should eq(senders)
            transaction.recipients.should eq(recipients)
          end
        end
      end
    end

    describe "#unpermitted_call" do
      it "should raise an error: Missing hash key call" do
          with_factory do |block_factory, transaction_factory|
          payload = {unknown: "unknown"}.to_json
          json = JSON.parse(payload)

          expect_raises(Exception, %{Missing hash key: "call"}) do
            block_factory.rpc.exec_internal_post(json, MockContext.new.unsafe_as(HTTP::Server::Context), {} of String => String)
          end
        end
      end

      it "should return a 403 when the rpc call is unknown" do
        with_factory do |block_factory, transaction_factory|
          payload = {call: "unknown"}.to_json
          json = JSON.parse(payload)

          with_rpc_exec_internal_post(block_factory.rpc, json, 403) do |result|
            result.should eq("unpermitted call: unknown")
          end
        end
      end
    end
  end

  describe "#exec_internal_get" do
    it "should return an unpermitted call response" do
        with_factory do |block_factory, transaction_factory|
        payload = {call: "unknown"}.to_json
        json = JSON.parse(payload)

        with_rpc_exec_internal_get(block_factory.rpc, 403) do |result|
          result.should eq("unpermitted method: GET")
        end
      end
    end
  end

  STDERR.puts "< Node::RPCController"
end

# def expected_headers
#   %{[{"index":0,"nonce":0,"prev_hash":"genesis","merkle_tree_root":""},{"index":1,"nonce":1103761249925206526,"prev_hash":"5396e18efa80a8e891c417fff862d7cad171465e65bc4b4e5e1c1c3ab0aeb88f","merkle_tree_root":"60ebe5469446a0e2b60b80972ebfb8b63f971477"},{"index":2,"nonce":11121314448198599040,"prev_hash":"a50254a09ee8b6325e2c044048dde963b8d2433817f13fbb829a9ac96c1dc68a","merkle_tree_root":"3f1a5c8c4bf63354a0a4bb5915c7484d5adc2a38"},{"index":3,"nonce":13464266234315212144,"prev_hash":"163b5df7a9eaeaf6972cf1b72f691f3ccd2d4a37591b260b6d64bba54c0066a7","merkle_tree_root":"16213992f29533ee88664437ad509d25856db289"},{"index":4,"nonce":11260396040783499427,"prev_hash":"4db27287cf41be06ec066b405c828566a1da41273486e69e2e222ec5d0700679","merkle_tree_root":"e5cc88f1c6c97ddc807d8e806ce4caf9b893330d"},{"index":5,"nonce":13385362284715168141,"prev_hash":"2295078aaf6dfac6aaed8b6a7bd253cc36513c81dad402e69b04810e8e6048e1","merkle_tree_root":"7694714cbc5239e4d7b406000a4883b0cbbf41ad"},{"index":6,"nonce":15944612208300140906,"prev_hash":"787bc7571af8fe0594caebf42e07f90c410ef05844c90854327ac8d1ea56f48b","merkle_tree_root":"73d4ba5b4e3ca9f2614fdb70364e08158c2a9a79"},{"index":7,"nonce":9047169216954437053,"prev_hash":"249106a47bc92dd43c068db99e92e034c132ffdfe78fc22078f55771a71c02f5","merkle_tree_root":"ac101de15327d1c439e141b19202f50d30b5f2b6"},{"index":8,"nonce":14548740937717102308,"prev_hash":"a9f234ce1b5b23225be373925f8e6ecc0dc1f8f68f5dbfa1262a1248aba96661","merkle_tree_root":"ac839ef0ec75181faf6251ff7044e52be93dbcdd"},{"index":9,"nonce":16958131682057411545,"prev_hash":"b13d9530ee0b4872fa4c01035b414b17113a1ec9e7a55b349dbc8bb051c0e71e","merkle_tree_root":"2621becb962b817e870813267cfc26f1ca8b470d"},{"index":10,"nonce":9587759897189510347,"prev_hash":"d286ad94158925bf888599a03fc7fd5c4a3c4c384197cfbd4c3f799e43eeff92","merkle_tree_root":"f288e4243b156b0da35d9e98d3c52594fe7e14d4"}]}
# end
#
# def expected_blockchain
#   %{[{"index":0,"transactions":[],"nonce":0,"prev_hash":"genesis","merkle_tree_root":""},{"index":1,"transactions":[{"id":"f2a4a3723fe054b91e560f1a1450812018d31f3a3e2fb3c8c765680e31df5ee4","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":10000}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":1103761249925206526,"prev_hash":"5396e18efa80a8e891c417fff862d7cad171465e65bc4b4e5e1c1c3ab0aeb88f","merkle_tree_root":"60ebe5469446a0e2b60b80972ebfb8b63f971477"},{"index":2,"transactions":[{"id":"7d925a249d161d895be689d8369c718e0800f8d735fc0fc46dfb09c4862de9e7","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":11121314448198599040,"prev_hash":"a50254a09ee8b6325e2c044048dde963b8d2433817f13fbb829a9ac96c1dc68a","merkle_tree_root":"3f1a5c8c4bf63354a0a4bb5915c7484d5adc2a38"},{"index":3,"transactions":[{"id":"1d0219500820a9be161c4ce1e1c2754c8811526e4bc26bf06a1c69b03dd17beb","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":13464266234315212144,"prev_hash":"163b5df7a9eaeaf6972cf1b72f691f3ccd2d4a37591b260b6d64bba54c0066a7","merkle_tree_root":"16213992f29533ee88664437ad509d25856db289"},{"index":4,"transactions":[{"id":"c7aeb946302384e4cb83365b73e47150f5c7c8ce93935a085f8dd785e84073f3","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":11260396040783499427,"prev_hash":"4db27287cf41be06ec066b405c828566a1da41273486e69e2e222ec5d0700679","merkle_tree_root":"e5cc88f1c6c97ddc807d8e806ce4caf9b893330d"},{"index":5,"transactions":[{"id":"1c4c5699d3837dfb406c054acc5644266befa4ab72a937ea9eaa7c4c4edb2ece","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":13385362284715168141,"prev_hash":"2295078aaf6dfac6aaed8b6a7bd253cc36513c81dad402e69b04810e8e6048e1","merkle_tree_root":"7694714cbc5239e4d7b406000a4883b0cbbf41ad"},{"index":6,"transactions":[{"id":"1e65a6bc52ea9a979cbb8782b19d7a57cbe70cefe1b95ba90fbd493ca51f7a85","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":15944612208300140906,"prev_hash":"787bc7571af8fe0594caebf42e07f90c410ef05844c90854327ac8d1ea56f48b","merkle_tree_root":"73d4ba5b4e3ca9f2614fdb70364e08158c2a9a79"},{"index":7,"transactions":[{"id":"65cb19d1b4a1dc800e309c4209a1ff1a0e640441061df0310cacd94dffa560d3","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":9047169216954437053,"prev_hash":"249106a47bc92dd43c068db99e92e034c132ffdfe78fc22078f55771a71c02f5","merkle_tree_root":"ac101de15327d1c439e141b19202f50d30b5f2b6"},{"index":8,"transactions":[{"id":"5c244b1f7a75b9421a3d120446b819432f0c73997f0ecbb10adc2749f0d95443","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":14548740937717102308,"prev_hash":"a9f234ce1b5b23225be373925f8e6ecc0dc1f8f68f5dbfa1262a1248aba96661","merkle_tree_root":"ac839ef0ec75181faf6251ff7044e52be93dbcdd"},{"index":9,"transactions":[{"id":"66db8c31cb20eedadbe825305fc542dbc113082f7e7e49a2f0d7001c147f656b","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":16958131682057411545,"prev_hash":"b13d9530ee0b4872fa4c01035b414b17113a1ec9e7a55b349dbc8bb051c0e71e","merkle_tree_root":"2621becb962b817e870813267cfc26f1ca8b470d"},{"index":10,"transactions":[{"id":"8fc33ce4ca8e0953312a31085823c535014484541d2414b2c9da08deccdaa45f","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":9587759897189510347,"prev_hash":"d286ad94158925bf888599a03fc7fd5c4a3c4c384197cfbd4c3f799e43eeff92","merkle_tree_root":"f288e4243b156b0da35d9e98d3c52594fe7e14d4"}]}
# end
#
# def expected_transactions
#   %{[{"id":"f2a4a3723fe054b91e560f1a1450812018d31f3a3e2fb3c8c765680e31df5ee4","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":10000}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}]}
# end
#
# def expected_transaction
#   %{{"id":"7d925a249d161d895be689d8369c718e0800f8d735fc0fc46dfb09c4862de9e7","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}}
# end
#
# def expected_block
#   %{{"index":2,"transactions":[{"id":"7d925a249d161d895be689d8369c718e0800f8d735fc0fc46dfb09c4862de9e7","action":"head","senders":[],"recipients":[{"address":"TTBjOGYyMDJjZjVmNjg0YzhmNTBlNTRmNGQ3ZjFiZDRkNzE4NTkzODM2NDlmODZi","amount":2500},{"address":"TTA4NjNiMjIzNjMwYjViOGVmMmYwZjU0YTFkNTE5YmQ2MWIyYmFiOGIyODVlNTk5","amount":7500}],"message":"0","prev_hash":"0","sign_r":"0","sign_s":"0"}],"nonce":11121314448198599040,"prev_hash":"a50254a09ee8b6325e2c044048dde963b8d2433817f13fbb829a9ac96c1dc68a","merkle_tree_root":"3f1a5c8c4bf63354a0a4bb5915c7484d5adc2a38"}}
# end
#
# def expected_block_header
#   %{{"index":2,"nonce":11121314448198599040,"prev_hash":"a50254a09ee8b6325e2c044048dde963b8d2433817f13fbb829a9ac96c1dc68a","merkle_tree_root":"3f1a5c8c4bf63354a0a4bb5915c7484d5adc2a38"}}
# end
