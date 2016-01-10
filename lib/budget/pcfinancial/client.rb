require 'mechanize'
require 'budget/null_logger'

module Budget
  module PcFinancial
    class Client
      def initialize(client_num, password, logger: ::Budget::NullLogger)
        @logger = logger
        @client_num = client_num
        @password = password
        @agent = Mechanize.new
        @logged_in = false
      end

      def list_accounts
        login! unless @logged_in

        page = goto_download_page!

        form = page.form('DownloadTransactionsForm')

        field = form.field_with(name: 'fromAccount')

        field.options.map { |opt| opt.text[/\[(\d+)\]/, 1] }
      end

      def download_transactions(account_num, since = nil)
        login! unless @logged_in

        page = goto_download_page!
        form = page.form('DownloadTransactionsForm')

        select_account!(form, account_num)

        set_date_range!(form, since)

        # choose CSV format
        form.radiobuttons_with(name: 'pfmSoftware', value: 'other').first.check

        # get the data!
        result = @agent.submit(form, form.buttons.last)

        result.body
      end

      private

      def goto_download_page!
        @agent.get 'https://www.txn.banking.pcfinancial.ca/a/banking/accounts/downloadTransactions1.ams'
      end

      def login!
        page = @agent.get('https://www.txn.banking.pcfinancial.ca/a/authentication/preSignOn.ams')
        form = page.form('SignOnForm')
        form.cardNumber = @client_num
        form.password = @password
        @agent.submit(form, form.buttons.first)
        @logged_in = true
      end

      # since last download (since == nil) or since a given date (Time)
      def set_date_range!(form, since = nil)
        since_value = since.nil? ? 'true' : 'false'
        form.radiobuttons_with(name: 'sinceLastDownload', value: since_value).last.check

        return if since.nil?

        form.fromDate__DAY = since.day
        form.fields_with('fromDate__MONTH').first.options_with(value: (since.month - 1).to_s).first.select
        form.fromDate__YEAR = since.year
      end

      def select_account!(form, account_num)
        field = form.field_with(name: 'fromAccount')
        pattern = "\\[#{account_num}\\]"
        field.options_with(text: Regexp.new(pattern)).first.select
      end
    end
  end
end
