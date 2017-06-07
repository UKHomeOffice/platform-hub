require 'rails_helper'

RSpec.describe Announcement, type: :model do

  include_context 'time helpers'

  describe 'update protections' do
    it 'should not allow updates after the initial status' do
      a = create :announcement, title: 'foo'
      expect(a.title).to eq 'foo'

      a.update title: 'bar'
      expect(a.title).to eq 'bar'

      a.update status: :delivering

      expect {
        a.update title: 'baz'
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'should not allow updates after publish_at has been reached' do
      a = create :announcement, title: 'foo', publish_at: now + 1.hour
      expect(a.title).to eq 'foo'

      a.update title: 'bar'
      expect(a.title).to eq 'bar'

      a.update publish_at: now - 1.hour

      expect {
        a.update title: 'baz'
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'should still allow direct column update' do
      a = create :announcement, title: 'foo'
      expect(a.title).to eq 'foo'

      a.update status: :delivering

      previous_sticky = a.is_sticky
      a.update_column :is_sticky,  !previous_sticky

      a2 = Announcement.find a.id
      expect(a2.is_sticky).to be !previous_sticky
    end

    it 'should still allow deletion' do
      a = create :announcement, title: 'foo'
      expect(a.title).to eq 'foo'

      a.update status: :delivering

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

end
