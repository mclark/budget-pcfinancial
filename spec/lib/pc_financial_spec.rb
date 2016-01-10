require 'pc_financial/transaction_builder.rb'
require 'pc_financial/import_controller.rb'

DATA_PATH = Pathname.new(__FILE__) + '../../data'

describe PcFinancial::TransactionBuilder do
  subject { PcFinancial::TransactionBuilder.new.parse(data) }

  let(:data) { (DATA_PATH + 'account1.csv').read }

  its(:length) { is_expected.to eql(4) }

  it 'has unique transaction ids for all records' do
    expect(subject.map(&:id).uniq.length).to eql(4)
  end

  it 'has the same transaction ids on subsequent parses' do
    expect(subject).to eql(PcFinancial::TransactionBuilder.new.parse(data))
  end

  context 'with overlapping transactions added' do
    let(:additional) do
      extra_data = (DATA_PATH + 'account1-2.csv').read
      PcFinancial::TransactionBuilder.new.parse(extra_data)
    end

    before { subject.concat(additional).uniq! }

    its(:length) { is_expected.to eql(6) }

    it 'has the expected transactions in the expected order' do
      expect(subject.map(&:notes)).to eql([
        'CHEQUE #15  , SUPERFLUOUS TEXT', 'TRANSFER IN', 'POS MERCHANDISE AMERICAN EAGLE',
        'POS MERCHANDISE AMERICAN EAGLE', 'TIM HORTONS', 'PRESTO'])

      d1 = Date.new(2015, 4, 6)
      d2 = Date.new(2015, 4, 7)
      expect(subject.map(&:date)).to eql([d1, d1, d1, d1, d1, d2])

      expect(subject.map(&:amount)).to eql([
        -54_300, 20_000, -4231, -4231, -567, -12_000])
    end
  end
end

describe PcFinancial::ImportController do
  let(:txns) { double(:txns) }
  let(:since) { Date.new(2013, 1, 1) }
  let(:accounts) { ['1'] }
  let(:client) { double(:client) }
  let(:builder) { double(:builder) }
  let(:txn_data) { double(:txn_data) }

  subject do
    PcFinancial::ImportController.new(client, builder: builder)
      .fetch(accounts: accounts, since: since)
  end

  before do
    # stub sleep for quicker tests
    allow_any_instance_of(PcFinancial::ImportController).to receive(:sleep).and_return(nil)
  end

  context 'with an account specified' do
    before do
      expect(client).to receive(:download_transactions).with('1', since).and_return(txn_data)

      expect(builder).to receive(:parse).with(txn_data).once.and_return(txns)
    end

    it { is_expected.to eql('1' => txns) }
  end

  context 'with no account specified' do
    let(:accounts) { nil }

    before do
      expect(client).to receive(:list_accounts).once.and_return(%w(1 2))
      expect(client).to receive(:download_transactions).once.with('1', since).and_return(txn_data)
      expect(client).to receive(:download_transactions).once.with('2', since).and_return(txn_data)

      expect(builder).to receive(:parse).with(txn_data).twice.and_return(txns)
    end

    it { is_expected.to eql('1' => txns, '2' => txns) }
  end
end
