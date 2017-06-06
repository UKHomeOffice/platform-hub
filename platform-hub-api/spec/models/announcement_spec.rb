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

    it 'should not allow updates after published_at has been reached' do
      a = create :announcement, title: 'foo', published_at: now + 1.hour
      expect(a.title).to eq 'foo'

      a.update title: 'bar'
      expect(a.title).to eq 'bar'

      a.update published_at: now - 1.hour

      expect {
        a.update title: 'baz'
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe 'scope: published' do
    before do
      @a1 = create :announcement, published_at: (now - 1.second)
      @a2 = create :announcement, published_at: (now + 1.hour)
      @a3 = create :announcement, published_at: (now - 1.hour)
    end

    it 'should only show announcements that are currently published and ordered by published date (desc)' do
      expect(Announcement.published.entries).to eq [@a1, @a3]

      move_time_to now + 2.hours

      expect(Announcement.published.entries).to eq [@a2, @a1, @a3]
    end
  end

end
