module ::Sushi::Core
  class UTXO < DApp
    # todo: detach transaction_indices
    @utxo_internal : Array(Hash(String, Int64)) = Array(Hash(String, Int64)).new
    @transaction_indices : Hash(String, Int64) = Hash(String, Int64).new

    def get(address : String) : Int64
      return 0_i64 if @utxo_internal.size < CONFIRMATION

      @utxo_internal.reverse[(CONFIRMATION - 1)..-1].each do |utxo_internal|
        return utxo_internal[address] if utxo_internal[address]?
      end

      0_i64
    end

    def get_unconfirmed(address : String, transactions : Array(Transaction)) : Int64
      utxos_transactions = 0_i64

      transactions.each do |transaction|
        utxos_transaction_senders = transaction.senders.select { |s| s[:address] == address }
        utxos_transaction_recipients = transaction.recipients.select { |r| r[:address] == address }
        utxos_transaction = utxos_transaction_recipients.reduce(0_i64) { |sum, utxo| prec(sum + utxo[:amount]) } -
                            utxos_transaction_senders.reduce(0_i64) { |sum, utxo| prec(sum + utxo[:amount] + utxo[:fee]) }

        utxos_transactions = prec(utxos_transactions + utxos_transaction)
      end

      unconfirmed_recorded = get_unconfirmed_recorded(address)
      prec(utxos_transactions + unconfirmed_recorded)
    end

    def get_unconfirmed_recorded(address : String) : Int64
      return 0_i64 if @utxo_internal.size == 0

      @utxo_internal.reverse.each do |utxo_internal|
        return utxo_internal[address] if utxo_internal[address]?
      end

      0_i64
    end

    def related?(action : String) : Bool
      action == "send"
    end

    def valid?(transaction : Transaction, prev_transactions : Array(Transaction)) : Bool
      raise "senders have to be only one currently" if transaction.senders.size != 1
      raise "recipients have to be only one currently" if transaction.recipients.size != 1

      sender = transaction.senders[0]
      senders_amount = get_unconfirmed(sender[:address], prev_transactions)

      if prec(senders_amount - sender[:amount]) < 0_i64
        raise "sender has not enough coins: #{sender[:address]} (#{senders_amount})"
      end

      true
    end

    def record(chain : Models::Chain)
      return if @utxo_internal.size >= chain.size

      chain[@utxo_internal.size..-1].each do |block|
        @utxo_internal.push(Hash(String, Int64).new)

        block_utxo = block.calculate_utxo
        block_utxo[:utxo].each do |address, amount|
          @utxo_internal[-1][address] ||= get_unconfirmed_recorded(address)
          @utxo_internal[-1][address] = prec(@utxo_internal[-1][address] + amount)
        end

        @transaction_indices = @transaction_indices.merge(block_utxo[:indices])
      end
    end

    def index(transaction_id : String) : Int64?
      @transaction_indices[transaction_id]?
    end

    def clear
      @utxo_internal.clear
      @transaction_indices.clear
    end

    include Logger
    include Consensus
    include Common::Num
    include Common::Color
  end
end