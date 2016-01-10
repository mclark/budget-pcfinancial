
module Budget
  module PcFinancial
    class Transaction
      # @attr amount transaction value, in cents
      # @attr date the date of the transaction
      # @attr notes [String] the notes, or description of the transaction
      # @attr id the unique (within the scope of the account) transaction id
      attr_reader :date, :amount, :notes, :id

      # Creates a new transaction.
      #
      # @note Exactly one of debit or credit is required.
      #
      # @param date [String] the date in mm/dd/yy format
      # @param notes [String] description of the transaction
      # @param amount [Float] the credit (debit) amount of the transaction in dollars
      # @param id [String] the unique (within this account) id of the transaction
      def initialize(date:, notes:, amount:, id:)
        self.date = date
        self.amount = amount
        self.notes = notes.strip
        self.id = id
      end

      def expense?
        amount < 0
      end

      def ==(other)
        Transaction === other && other.id == id
      end

      alias_method :eql?, :==

      delegate :hash, to: :id

      private

      attr_writer :expense, :notes, :id

      def date=(val)
        m, d, y = val.match(%r{(\d+)/(\d+)/(\d+)}).to_a.drop(1).map(&:to_i)
        @date = Date.new(y, m, d)
      end

      def amount=(val)
        # potential rounding errors, but nothing that matters on this scale
        @amount = (val * 100).to_i
      end
    end
  end
end
