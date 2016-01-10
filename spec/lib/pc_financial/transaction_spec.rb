require 'pc_financial/transaction'

describe PcFinancial::Transaction do
  subject { PcFinancial::Transaction.new(txn_data) }

  context 'with valid debit data' do
    let(:txn_data) { { date: '10/23/2014', notes: 'test', amount: -53.99, id: 'hello' } }

    its(:date) { is_expected.to eql(Date.new(2014, 10, 23)) }

    its(:notes) { is_expected.to eql('test') }

    its(:amount) { is_expected.to eql(-5399) }

    its(:id) { is_expected.to eql('hello') }

    it { is_expected.to be_an_expense }
  end

  context 'with valid credit data' do
    let(:txn_data) { { date: '5/5/2015', notes: 'test credit    ', amount: 3.56, id: 'hello' } }

    its(:date) { is_expected.to eql(Date.new(2015, 5, 5)) }

    its(:notes) { is_expected.to eql('test credit') }

    its(:amount) { is_expected.to eql(356) }

    its(:id) { is_expected.to eql('hello') }

    it { is_expected.to_not be_an_expense }
  end

  context 'with no amount specified' do
    let(:txn_data) { { date: '5/5/2014', notes: 'derp' } }

    # TODO: haven't found a more concise way to express this one...
    it 'raises an argument error' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  context 'with matching transactions' do
    subject { PcFinancial::Transaction.new(date: '5/5/2015', notes: 'test', amount: -55.66, id: 'abc123') }
    let(:txn2) { PcFinancial::Transaction.new(date: '5/5/2015', notes: 'test', amount: -55.66, id: 'abc123') }

    it { is_expected.to eql(txn2) }

    its(:hash) { is_expected.to eql(txn2.hash) }
  end

  context 'with non-matching transactions' do
    subject { PcFinancial::Transaction.new(date: '5/5/2015', notes: 'test1', amount: -55.66, id: 'wtfbbq') }
    let(:txn2) { PcFinancial::Transaction.new(date: '5/5/2015', notes: 'test2', amount: -55.66, id: 'abc123') }

    it { is_expected.to_not eql(txn2) }

    its(:hash) { is_expected.to_not eql(txn2.hash) }
  end
end
