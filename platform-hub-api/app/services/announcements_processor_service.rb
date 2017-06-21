class AnnouncementsProcessorService

  def initialize email_batch_size, logger
    @email_batch_size = email_batch_size
    @logger = logger
  end

  def run
    Announcement.published.awaiting_delivery.each(&method(:process))
  end

  private

  def process announcement
    @logger.info "Processing announcement #{announcement.id} - #{announcement.level} - '#{announcement.title}'"

    begin
      announcement.update! status: :delivering

      unless announcement.deliver_to.blank?
        process_for_email_delivery announcement
        process_for_slack_delivery announcement
      end

      # At this point we have to assume that any delivery mechanism triggered has
      # worked as expected
      announcement.update! status: :delivered
    rescue => e
      @logger.error "Failed to finish processing announcement #{announcement.id} - a partial delivery may have occurred! Exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join("\n")}"
      announcement.update! status: :delivery_failed
    end
  end

  def process_for_email_delivery announcement
    email_addresses = email_addresses_for announcement
    unless email_addresses.blank?
      @logger.info "Sending email to #{email_addresses.length} unique addresses (in batches of #{@email_batch_size})"

      email_addresses.each_slice(@email_batch_size) do |addresses|
        AnnouncementMailer.announcement_email(announcement, addresses).deliver_later
      end
    end
  end

  def process_for_slack_delivery announcement
    channels = announcement.deliver_to['slack_channels']
    unless channels.blank?
      @logger.info "Sending to slack channels: #{channels}"

      attachment = attachment_for_slack announcement
      icon = icon_for_slack announcement

      channels.each do |c|
        SLACK_NOTIFIER.post(
          attachments: [attachment],
          channel: c,
          icon_emoji: icon
        )
      end
    end
  end

  def email_addresses_for announcement
    hub_users_email_addresses =
      if announcement.deliver_to['hub_users'] == 'all'
        User.pluck(:email)
      else
        []
      end

    contact_lists = [announcement.deliver_to['contact_lists']].compact.flatten
    contact_lists_email_addresses = contact_lists.map do |id|
      ContactList.find(id).email_addresses.compact
    end.flatten

    (hub_users_email_addresses + contact_lists_email_addresses).uniq
  end

  def attachment_for_slack announcement
    {
      pretext: "<!channel> #{announcement.level.titleize}:",
      fallback: fallback_text_for_slack(announcement),
      color: color_for_slack(announcement),
      title: Slack::Notifier::Util::Escape.html(announcement.title),
      text: Slack::Notifier::Util::Escape.html(announcement.text)
    }
  end

  def fallback_text_for_slack announcement
    m = []
    m << "[#{announcement.level}] #{announcement.title}"
    m << announcement.text
    m.join(' - ');
  end

  def color_for_slack announcement
    case announcement.level
    when 'critical'
      'danger'
    when 'warning'
      'warning'
    else
      'good'
    end
  end

  def icon_for_slack announcement
    case announcement.level
    when 'critical'
      ':bangbang:'
    when 'warning'
      ':warning:'
    else
      ':information_source:'
    end
  end

end
