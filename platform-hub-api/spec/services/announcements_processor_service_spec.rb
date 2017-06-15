require 'rails_helper'

describe AnnouncementsProcessorService, type: :service do

  include_context 'time helpers'

  describe '#run' do
    let(:announcement_mailer) { class_double('announcement_mailer') }
    let(:slack_notifier) { instance_double('Slack::Notifier') }

    let!(:hub_user_1) { create :user, email: 'hub_user_1@example.org' }
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
        contact_lists: [ 'foo', 'bar' ],
        slack_channels: [ '#foo' ]
      }
    end
    let :expected_a5_recipients do
      (foo_contact_list.email_addresses + bar_contact_list.email_addresses).uniq
    end

    before do
      stub_const 'AnnouncementMailer', announcement_mailer
      stub_const 'SLACK_NOTIFIER', slack_notifier

      allow(ContactList).to receive(:find).with('foo').and_return(foo_contact_list)
      allow(ContactList).to receive(:find).with('bar').and_return(bar_contact_list)

      @a1 = create :announcement, publish_at: 1.hour.ago, status: :delivered
      @a2 = create :announcement, publish_at: 1.hour.ago, status: :awaiting_delivery, deliver_to: a2_deliver_to
      @a3 = create :announcement, publish_at: 1.minute.ago, status: :delivering
      @a4 = create :announcement, publish_at: 1.minute.ago, status: :awaiting_delivery, deliver_to: a4_deliver_to
      @a5 = create :announcement, publish_at: 1.hour.ago, status: :awaiting_delivery, deliver_to: a5_deliver_to
      @a6 = create :announcement, publish_at: 1.hour.from_now, status: :awaiting_delivery, deliver_to: {}
      @a7 = create :announcement, publish_at: 1.hour.ago, status: :awaiting_delivery, deliver_to: {}

      @service = AnnouncementsProcessorService.new 50, Rails.logger
    end

    it 'should process pending announcements that need to be delivered' do
      expect(@service).to receive(:process).with(@a2).and_call_original
      expect(@service).to receive(:process).with(@a4).and_call_original
      expect(@service).to receive(:process).with(@a5).and_call_original
      expect(@service).to receive(:process).with(@a7).and_call_original

      a2_mailer = double
      expect(announcement_mailer).to receive(:announcement_email).with(@a2, expected_a2_recipients).and_return(a2_mailer)
      expect(a2_mailer).to receive(:deliver_later)

      a4_mailer = double
      expect(announcement_mailer).to receive(:announcement_email).with(@a4, expected_a4_recipients).and_return(a4_mailer)
      expect(a4_mailer).to receive(:deliver_later)

      a5_mailer = double
      expect(announcement_mailer).to receive(:announcement_email).with(@a5, expected_a5_recipients).and_return(a5_mailer)
      expect(a5_mailer).to receive(:deliver_later)

      expect(slack_notifier).to receive(:ping)
        .with(anything, { channel: '#foo' })
        .exactly(2).times
      expect(slack_notifier).to receive(:ping)
        .with(anything, { channel: '#bar' })
        .once

      @service.run

      expect(@a2.reload.status).to eq 'delivered'
      expect(@a4.reload.status).to eq 'delivered'
      expect(@a5.reload.status).to eq 'delivered'
      expect(@a7.reload.status).to eq 'delivered'
    end

  end

end
