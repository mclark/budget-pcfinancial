require_relative 'client'
require_relative 'transaction_builder'

module Budget
  module PcFinancial
    class ImportController
      def initialize(client, builder: TransactionBuilder.new,
                             logger: Budget::NullLogger)
        @client = client
        @builder = builder
        @logger = logger
      end

      attr_reader :logger

      def fetch(accounts: nil, since: nil, save_files: true)
        # if unspecified, just download all accounts
        if accounts.nil?
          accounts = @client.list_accounts
          sleep(5)
        end

        transactions = {}

        Array.wrap(accounts).map do |num|
          sleep(5)

          logger.info "downloading transactions for #{num} since #{since}..."
          data = @client.download_transactions(num, since)

          File.write("#{num}.csv", data) if save_files

          transactions[num] = @builder.parse(data)
        end

        transactions
      end
    end
  end
end
