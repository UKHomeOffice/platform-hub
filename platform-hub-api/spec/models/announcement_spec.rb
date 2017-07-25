require 'rails_helper'

RSpec.describe Announcement, type: :model do

  include_context 'time helpers'

  describe 'update protections' do
    it 'should not allow updates after the initial status has changed, except for status field' do
      a = create :announcement, title: 'foo'
      expect(a.title).to eq 'foo'

      a.update! title: 'bar'
      expect(a.title).to eq 'bar'

      a.update! status: :delivering
      expect(a.status).to eq 'delivering'

      expect {
        a.update! title: 'baz'
      }.to raise_error(ActiveRecord::ReadOnlyRecord)

      a2 = Announcement.find(a.id)
      a2.update! status: :delivered
      expect(a2.status).to eq 'delivered'
    end

    it 'should not allow updates after publish_at has been reached, except for status field' do
      a = create :announcement, title: 'foo', publish_at: now + 1.hour
      expect(a.title).to eq 'foo'

      a.update! title: 'bar'
      expect(a.title).to eq 'bar'

      a.update! publish_at: now - 1.hour

      expect {
        a.update! title: 'baz'
      }.to raise_error(ActiveRecord::ReadOnlyRecord)

      a2 = Announcement.find(a.id)
      a2.update! status: :delivered
      expect(a2.status).to eq 'delivered'
    end

    it 'should still allow direct column update' do
      a = create :announcement, title: 'foo'
      expect(a.title).to eq 'foo'

      a.update! status: :delivering

      previous_sticky = a.is_sticky
      a.update_column :is_sticky,  !previous_sticky

      a2 = Announcement.find a.id
      expect(a2.is_sticky).to be !previous_sticky
    end

    it 'should still allow deletion' do
      a = create :announcement, title: 'foo'
      expect(a.title).to eq 'foo'

      a.update! status: :delivering

      # Need to reload before we can destroy it
      Announcement.find(a.id).destroy

      expect(Announcement.exists?(a.id)).to be false
    end
  end

  describe 'scope: published' do
    before do
      @a1 = create :announcement, publish_at: (now - 1.second)
      @a2 = create :announcement, publish_at: (now + 1.hour)
      @a3 = create :announcement, publish_at: (now - 1.hour)
    end

    it 'should only show announcements that are currently published and ordered by published date (desc)' do
      expect(Announcement.published.entries).to eq [@a1, @a3]

      move_time_to now + 2.hours

      expect(Announcement.published.entries).to eq [@a2, @a1, @a3]
    end
  end

  describe 'template or content presence checks' do
    context 'with missing template fields' do
      before do
        @a1 = build :announcement_from_template, original_template: nil, template_data: { 'a': 1 }
        @a2 = build :announcement_from_template, template_data: nil
      end

      it 'should be invalid' do
        expect(@a1).to be_invalid
        expect(@a1.errors[:original_template_id]).to match_array ["can't be blank"]

        expect(@a2).to be_invalid
        expect(@a2.errors[:template_data]).to match_array ["can't be blank"]
      end
    end

    context 'with all template fields specified' do
      before do
        @a = build :announcement_from_template
      end

      it 'should be valid' do
        expect(@a).to be_valid
      end
    end

    context 'with missing content fields' do
      before do
        @a1 = build :announcement, text: nil
        @a2 = build :announcement, title: nil
      end

      it 'should be invalid' do
        expect(@a1).to be_invalid
        expect(@a1.errors[:text]).to match_array ["can't be blank"]

        expect(@a2).to be_invalid
        expect(@a2.errors[:title]).to match_array ["can't be blank"]
      end
    end

    context 'with all content fields specified' do
      before do
        @a = build :announcement
      end

      it 'should be valid' do
        expect(@a).to be_valid
      end
    end
  end

  describe 'either template or content should be specified' do
    context 'neither is specified' do
      before do
        @a = build :announcement, title: nil, text: nil, original_template_id: nil, template_definitions: nil, template_data: nil
      end

      it 'should be invalid' do
        expect(@a).to be_invalid
        expect(@a.errors[:base]).to match_array ['either specify a template or content directly - currently neither is specified']
      end
    end

    context 'both have been specified' do
      before do
        @a = build :announcement_from_template, title: 'foo', text: 'bar'
      end

      it 'should be invalid' do
        expect(@a).to be_invalid
        expect(@a.errors[:base]).to match_array ['either a template can be specified or content directly, not both']
      end
    end
  end

end
