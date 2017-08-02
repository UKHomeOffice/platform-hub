require 'rails_helper'

RSpec.describe Announcement, type: :model do

  include_context 'time helpers'

  describe 'update protections' do
    it 'should not allow updates after the initial status (\'awaiting_delivery\') has changed, except for status field' do
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

    it 'should not allow updates for a published announcement, except for status field' do
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

    it 'should allow status change from the initial status (\'awaiting_delivery\') to \'delivering\'' do
      a = create :published_announcement

      a.update! status: :delivering
      expect(a.status).to eq 'delivering'
    end

    it 'should allow status change from \'awaiting_resend\' to another status' do
      a = create :published_announcement

      a.mark_for_resend!
      expect(a.status).to eq 'awaiting_resend'

      expect {
        a.update! title: 'baz'
      }.to raise_error(ActiveRecord::ReadOnlyRecord)

      a2 = Announcement.find(a.id)
      a2.update! status: :delivering
      expect(a2.status).to eq 'delivering'
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

  describe 'using a template' do

    context 'when creating an announcement' do
      let(:template) { create :announcement_template }

      it 'should set cache the template_definitions from the specified template' do
        a = create :announcement_from_template, original_template: template
        expect(a.original_template_id).to eq template.id
        expect(a.template_definitions).to eq template.spec['templates'].with_indifferent_access
      end
    end

    context 'when updating an announcement' do

      let :initial_template_definitions do
        {
          'title': 'Title {{field0}}',
          'on_hub': 'On hub {{field0}}',
          'email_html': 'Email HTML <p>{{field0}}</p>',
          'email_text': 'Email text {{field0}}',
          'slack': 'Slack {{field0}}'
        }
      end

      let :updated_template_definitions do
        {
          'title': 'NEW Title {{field0}}',
          'on_hub': 'NEW On hub {{field0}}',
          'email_html': 'NEW Email HTML <p>{{field0}}</p>',
          'email_text': 'NEW Email text {{field0}}',
          'slack': 'NEW Slack {{field0}}'
        }
      end

      let :initial_template do
        create :announcement_template, templates: initial_template_definitions
      end

      let :new_template do
        create :announcement_template, templates: updated_template_definitions
      end

      let :updated_spec do
        s = initial_template.spec.dup
        s['templates'] = updated_template_definitions
        s
      end

      context 'for an unpublished announcement' do

        before do
          @announcement = create :announcement_from_template, original_template: initial_template
        end

        context 'when the original template\'s definitions are updated' do
          it 'should sync the definitions on update' do
            initial_template.update! spec: updated_spec

            expect(@announcement.template_data).not_to eq updated_template_definitions.with_indifferent_access

            @announcement.update! is_sticky: !@announcement.is_sticky
            expect(@announcement.template_definitions).to eq updated_template_definitions.with_indifferent_access
          end
        end

        context 'when a whole new template is assigned' do
          it 'should use the new template\'s definitions' do
            @announcement.update! original_template_id: new_template.id

            expect(@announcement.template_definitions).to eq new_template.spec['templates'].with_indifferent_access
          end
        end

      end

      context 'for a new published announcement' do
        before do
          @announcement = create :published_announcement_from_template, original_template: initial_template
        end

        context 'when the original template\'s definitions are updated' do
          it 'should not sync the definitions on updates' do
            initial_template.update! spec: updated_spec

            expect(@announcement.template_data).not_to eq updated_template_definitions.with_indifferent_access

            @announcement.update! status: :delivering
            expect(@announcement.template_definitions).to eq initial_template_definitions.with_indifferent_access
          end
        end

        context 'when a whole new template is assigned' do
          it 'should not allow the original_template_id to be changed and it should not mutate template_definitions' do
            expect {
              @announcement.update! original_template_id: new_template.id
            }.to raise_error(ActiveRecord::ReadOnlyRecord)

            expect(@announcement.template_definitions).to eq initial_template.spec['templates']
            expect(Announcement.find(@announcement.id).template_definitions).to eq initial_template.spec['templates'].with_indifferent_access
          end
        end
      end

      context 'for an announcement that becomes published' do
        before do
          @announcement = create :announcement_from_template, original_template_id: initial_template
          @announcement.update! publish_at: now
        end

        context 'when the original template\'s definitions are updated' do
          it 'should not sync the definitions on updates' do
            initial_template.update! spec: updated_spec

            expect(@announcement.template_data).not_to eq updated_template_definitions.with_indifferent_access

            @announcement.update! status: :delivering
            expect(@announcement.template_definitions).to eq initial_template_definitions.with_indifferent_access
          end
        end

        context 'when a whole new template is assigned' do
          it 'should not allow the original_template_id to be changed and it should not mutate template_definitions' do
            expect {
              @announcement.update! original_template_id: new_template.id
            }.to raise_error(ActiveRecord::ReadOnlyRecord)

            expect(@announcement.template_definitions).to eq initial_template.spec['templates'].with_indifferent_access
            expect(Announcement.find(@announcement.id).template_definitions).to eq initial_template.spec['templates'].with_indifferent_access
          end
        end
      end

    end

  end

end
