require 'csv'
require_relative 'transaction'

module Budget
  module PcFinancial
    class TransactionBuilder
      def parse(data)
        data = CSV.parse(data).drop(1).map { |r| normalize(r) }
        with_txn_id(data).map do |date, notes, amount, txn_id|
          Transaction.new(date: date, notes: notes, amount: amount, id: txn_id)
        end
      end

      private

      def with_txn_id(data)
        # group by date
        grouped = data.group_by { |r| r[0] }.values
        grouped.map do |day|
          # add an index counter so two identical transactions don't get the same hash
          # but the same one will get the same hash on subsequent runs
          day.map.with_index do |txn, i|
            # hash it so it is sufficiently unique
            txn << Digest::SHA1.hexdigest(txn.join + i.to_s)
          end
        end

        # return to an array of arrays
        numbered = []
        grouped.each { |day| numbered += day }
        numbered
      end

      # normalize the row lengths. by default, debits have 3 entries, credits have 4.
      # also, entries are not properly escaped which is completely ridiculous.
      def normalize(row)
        # date is always the first element
        date = row.shift

        # amount is always the last
        amount = row.pop.to_f

        # we'll assume that if the second to last element is blank, then the amount
        # is a credit. If the description ever terminates with a command and
        # whitespace, we're screwed.  but we were already screwed when our source
        # didn't bother to learn how CSV worked.
        amount = -amount unless row.last.blank?
        row.pop if row.last.blank?

        notes = row.join(',')
        [date, notes, amount]
      end
    end
  end
end
