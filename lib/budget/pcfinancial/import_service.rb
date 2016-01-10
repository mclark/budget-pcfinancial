require_relative 'import_job'

module Budget
  module PcFinancial
    class ImportService < ImportService
      preference :client_number
      preference :password

      define_singleton_method(:description) { 'PC Financial CSV Import Service' }

      def call(options)
        ImportJob.new(
          client_number: preferred_client_number,
          password: preferred_password,
          logger: options.delete(:logger)
        ).call(options.slice(:accounts, :since))
      end
    end
  end
end

ImportService.register(Budget::PcFinancial::ImportService)
