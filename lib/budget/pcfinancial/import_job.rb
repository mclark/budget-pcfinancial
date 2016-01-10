require_relative 'import_controller'
require_relative 'client'

module Budget
  module PcFinancial
    class ImportJob
      def initialize(client_number: nil, password: nil, controller: nil, logger: Budget::NullLogger)
        @controller = controller

        @controller ||= PcFinancial::ImportController.new(
          PcFinancial::Client.new(client_number, password, logger: logger)
        )

        @logger = logger
      end

      # TODO: integrate matt's work better
      def call(accounts: nil, since: nil)
        txn_data = controller.fetch(accounts: accounts, since: since)

        logger.info 'ingesting transactions...'

        txn_data.each_pair do |account, txns|
          a = ImportableAccount.find_or_initialize_by(source_id: account)
          a.name = account
          a.save

          txns.each do |txn|
            t = ImportableTransaction.find_or_initialize_by(source_id: txn.id)

            t.date = txn.date
            t.description = txn.notes
            t.category = 'unknown'
            t.expense = txn.expense?
            t.cents = txn.amount.abs
            t.account = account
            t.account_id = a.source_id
            t.source_id = txn.id

            t.save
          end
        end
      end

      private

      attr_reader :controller, :logger
    end
  end
end
