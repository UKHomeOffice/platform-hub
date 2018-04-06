require 'rails_helper'

RSpec.describe CostsReport, type: :model do

  describe '.exists_for?' do
    context 'when it doesn\'t exist' do
      it 'should return false' do
        expect(CostsReport.exists_for?(2017, 'Jan')).to be false
      end
    end

    context 'when it does exist' do
      subject { create :costs_report }

      it 'should return true' do
        expect(CostsReport.exists_for?(subject.year, subject.month)).to be true
      end
    end
  end

  describe '.already_published?' do
    context 'when it doesn\'t exist' do
      it 'should return false' do
        expect(CostsReport.already_published?(2017, 'Jan')).to be false
      end
    end

    context 'when it does exist' do
      subject { create :costs_report, published_at: nil }

      context 'when not published yet' do
        it 'should return false' do
          expect(CostsReport.already_published?(2017, 'Jan')).to be false
        end
      end

      context 'after being published' do
        before do
          subject.publish!
        end

        it 'should return true' do
          expect(CostsReport.already_published?(subject.year, subject.month)).to be true
        end
      end
    end
  end

  describe '.generate_id_for' do
    it 'should generate an ID value as expected' do
      expect(CostsReport.generate_id_for(2017, 'Jan')).to eq '2017-01'
    end

    it 'should handle invalid values' do
      expect(CostsReport.generate_id_for(2017, 'unknown')).to eq nil
    end
  end

  describe '#id' do
    it { is_expected.to allow_value('2017-01').for(:id) }
    it { is_expected.to allow_value('2017-10').for(:id) }
    it { is_expected.to allow_value('0000-00').for(:id) }

    it { is_expected.not_to allow_value('foo').for(:id) }
    it { is_expected.not_to allow_value('2017-Jan').for(:id) }
    it { is_expected.not_to allow_value('---').for(:id) }
    it { is_expected.not_to allow_value('1').for(:id) }
    it { is_expected.not_to allow_value('2017').for(:id) }
    it { is_expected.not_to allow_value('201710').for(:id) }
  end

  describe '#year' do
    it { is_expected.to allow_value(2017).for(:year) }
    it { is_expected.to allow_value(1111).for(:year) }
    it { is_expected.to allow_value(9999).for(:year) }

    it { is_expected.not_to allow_value(1).for(:year) }
  end

  describe '#month' do
    it { is_expected.to allow_value('Jan').for(:month) }
    it { is_expected.to allow_value('Dec').for(:month) }

    it { is_expected.not_to allow_value('January').for(:month) }
    it { is_expected.not_to allow_value('J').for(:month) }
    it { is_expected.not_to allow_value('jan').for(:month) }
    it { is_expected.not_to allow_value('bla').for(:month) }
  end

  describe '#set_id callback' do
    let(:year) { 2017 }
    let(:month) { 'Dec' }

    subject { create :costs_report, year: year, month: month }

    let(:expected_id) { '2017-12' }

    it 'should set the id field accordingly' do
      expect(subject.id).to eq expected_id
    end
  end

  describe 'readonly? check' do
    it 'reports should not be updateable after publishing' do
      r = create :costs_report

      # Updateable
      r.update! notes: 'foo bar'
      expect(r.reload.notes).to eq 'foo bar'

      # Now publish...
      r.publish!

      # ... not updateable anymore!
      expect {
        r.update! notes: 'foo bar 2'
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'reports should not be destroyable after publishing but should still be deleteable directly in the db' do
      expect(CostsReport.count).to eq 0

      # Publish it...
      r = create :costs_report
      r.publish!

      # ... not destroyable
      expect{
        CostsReport.find(r.id).destroy!
      }.to raise_error(ActiveRecord::ReadOnlyRecord)

      # ... but is still deleteable
      expect{
        CostsReport.find(r.id).delete
      }.not_to raise_error

      expect(CostsReport.count).to eq 0
    end
  end

end
