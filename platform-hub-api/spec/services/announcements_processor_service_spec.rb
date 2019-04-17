require 'rails_helper'

describe AnnouncementsProcessorService, type: :service do

  include_context 'time helpers'

  describe '#run' do

    context 'with announcements feature flag enabled' do
      before do
        FeatureFlagService.create_or_update(:announcements, true)
      end

      let(:announcement_mailer) { class_double('announcement_mailer') }
      let(:slack_notifier) { instance_double('Slack::Notifier') }

      let!(:hub_user_1) { create :user, email: 'hub_user_1@example.org', created_at: 1.second.ago }
      let!(:hub_user_2) { create :user, email: 'hub_user_2@example.org' }

      let :foo_contact_list do
        instance_double 'ContactList',
          id: 'foo',
          email_addresses: [ hub_user_2.email, 'foo@example.org' ]
      end
      let :bar_contact_list do
        instance_double 'ContactList',
          id: 'bar',
          email_addresses: [ 'bar@example.org', 'foo@example.org' ]
      end

      let :a2_deliver_to do
        {
          hub_users: 'none',
          contact_lists: 'foo',
          slack_channels: [ '#foo', '#bar' ]
        }
      end
      let :expected_a2_recipients do
        foo_contact_list.email_addresses
      end

      let :a4_deliver_to do
        {
          hub_users: 'all',
          contact_lists: [ 'foo', 'bar' ],
          slack_channels: []
        }
      end
      let :expected_a4_recipients do
        ([ hub_user_1.email, hub_user_2.email ] + foo_contact_list.email_addresses + bar_contact_list.email_addresses).uniq
      end

      let :a5_deliver_to do
        {
          hub_users: '',
          contact_lists: [],
          slack_channels: [ '#foo' ]
        }
      end

      let :a10_deliver_to do
        {
          hub_users: 'all',
          contact_lists: [ 'foo', 'bar' ],
          slack_channels: [ '#baz' ]
        }
      end
      let :expected_a10_recipients do
        ([ hub_user_1.email, hub_user_2.email ] + foo_contact_list.email_addresses + bar_contact_list.email_addresses).uniq
      end

      let :a11_deliver_to do
        {
          hub_users: 'all',
          contact_lists: [ 'foo', 'bar' ],
          slack_channels: [ '#baz' ]
        }
      end
      let :expected_a11_recipients do
        ([ hub_user_1.email, hub_user_2.email ] + foo_contact_list.email_addresses + bar_contact_list.email_addresses).uniq
      end

      before do
        stub_const 'AnnouncementMailer', announcement_mailer
        stub_const 'SLACK_NOTIFIER', slack_notifier

        allow(ContactList).to receive(:find).with('foo').and_return(foo_contact_list)
        allow(ContactList).to receive(:find).with('bar').and_return(bar_contact_list)

        @a1 = create :announcement, publish_at: 1.hour.ago, status: :delivered
        @a2 = create :announcement, publish_at: 1.minute.ago, status: :awaiting_delivery, deliver_to: a2_deliver_to
        @a3 = create :announcement, publish_at: 1.minute.ago, status: :delivering
        @a4 = create :announcement, publish_at: 1.hour.ago, status: :awaiting_delivery, deliver_to: a4_deliver_to
        @a5 = create :announcement, publish_at: 2.hours.ago, status: :awaiting_delivery, deliver_to: a5_deliver_to
        @a6 = create :announcement, publish_at: 1.hour.from_now, status: :awaiting_delivery, deliver_to: { hub_users: 'all' }
        @a7 = create :announcement, publish_at: 3.hours.ago, status: :awaiting_delivery, deliver_to: {}
        @a8 = create :announcement, publish_at: 4.hours.ago, status: :awaiting_delivery, deliver_to: { slack_channels: [], contact_lists: [] }
        @a9 = create :announcement, publish_at: 1.hour.ago, status: :awaiting_delivery, deliver_to: { hub_users: nil }
        @a10 = create :announcement, publish_at: 5.hours.ago, status: :awaiting_resend, deliver_to: a10_deliver_to
        @a11 = create :announcement_from_template, publish_at: 6.hours.ago, status: :awaiting_delivery, deliver_to: a11_deliver_to
        @a12 = create :announcement_from_template, publish_at: 1.hour.from_now, status: :awaiting_resend, deliver_to: { hub_users: 'all' }

        @service = AnnouncementsProcessorService.new 50, Rails.logger
      end

      it 'should process pending announcements that need to be delivered' do
        expect(@service).to receive(:process).with(@a2).and_call_original
        a2_mailer = double
        expect(announcement_mailer).to receive(:announcement_email).with(
          @a2.tap { |a| a.status = :delivering },
          expected_a2_recipients,
          false
        ).and_return(a2_mailer)
        expect(a2_mailer).to receive(:deliver_later)
        expect(slack_notifier).to receive(:post)
          .with(attachments: anything, channel: '#foo', icon_emoji: anything)
        expect(slack_notifier).to receive(:post)
          .with(attachments: anything, channel: '#bar', icon_emoji: anything)

        expect(@service).to receive(:process).with(@a4).and_call_original
        a4_mailer = double
        expect(announcement_mailer).to receive(:announcement_email).with(
          @a4.tap { |a| a.status = :delivering },
          expected_a4_recipients,
          false
        ).and_return(a4_mailer)
        expect(a4_mailer).to receive(:deliver_later)

        expect(@service).to receive(:process).with(@a5).and_call_original
        expect(slack_notifier).to receive(:post)
          .with(attachments: anything, channel: '#foo', icon_emoji: anything)

        expect(@service).to receive(:process).with(@a7).and_call_original

        expect(@service).to receive(:process).with(@a8).and_call_original

        expect(@service).to receive(:process).with(@a9).and_call_original

        expect(@service).to receive(:process).with(@a10).and_call_original
        a10_mailer = double
        expect(announcement_mailer).to receive(:announcement_email).with(
          @a10.tap { |a| a.status = :delivering },
          expected_a10_recipients,
          true
        ).and_return(a10_mailer)
        expect(a10_mailer).to receive(:deliver_later)
        expect(slack_notifier).to receive(:post)
          .with(attachments: anything, channel: '#baz', icon_emoji: anything)

        expect(@service).to receive(:process).with(@a11).and_call_original
        a11_mailer = double
        expect(announcement_mailer).to receive(:announcement_email).with(
          @a11.tap { |a| a.status = :delivering },
          expected_a10_recipients,
          false
        ).and_return(a11_mailer)
        expect(a11_mailer).to receive(:deliver_later)
        expect(slack_notifier).to receive(:post)
          .with(attachments: anything, channel: '#baz', icon_emoji: anything)

        @service.run

        expect(@a1.reload.status).to eq 'delivered'
        expect(@a2.reload.status).to eq 'delivered'
        expect(@a3.reload.status).to eq 'delivering'
        expect(@a4.reload.status).to eq 'delivered'
        expect(@a5.reload.status).to eq 'delivered'
        expect(@a6.reload.status).to eq 'awaiting_delivery'
        expect(@a7.reload.status).to eq 'delivery_not_required'
        expect(@a8.reload.status).to eq 'delivery_not_required'
        expect(@a9.reload.status).to eq 'delivery_not_required'
        expect(@a10.reload.status).to eq 'delivered'
        expect(@a11.reload.status).to eq 'delivered'
      end
    end

    context 'with announcements feature flag disabled' do
      before do
        FeatureFlagService.create_or_update(:announcements, false)
      end

      it 'should not do anything' do
        service = AnnouncementsProcessorService.new(50, Rails.logger)

        expect(Announcement).to receive(:published).never
        expect(service).to receive(:process).never

        service.run
      end
    end

  end

end
