class AnnouncementsProcessorService

  def initialize email_batch_size, logger
    @email_batch_size = email_batch_size
    @logger = logger
  end

  def run
    return unless FeatureFlagService.is_enabled?(:announcements)

    Announcement.published.awaiting_delivery_or_resend.each(&method(:process))
  end

  private

  def process announcement
    title = if announcement.template_data.present?
      AnnouncementTemplateFormatterService.format(announcement.template_definitions, announcement.template_data).title
    else
      announcement.title
    end
    @logger.info "Processing announcement #{announcement.id} - #{announcement.level} - '#{title}'"

    begin

      is_reminder = announcement.awaiting_resend?

      announcement.update! status: :delivering

      if announcement.has_delivery_targets?
        process_for_email_delivery announcement, is_reminder
        process_for_slack_delivery announcement, is_reminder

        # At this point we have to assume that any delivery mechanism triggered has
        # worked as expected
        announcement.update! status: :delivered
      else
        announcement.update! status: :delivery_not_required
      end

    rescue => e
      @logger.error "Failed to finish processing announcement #{announcement.id} - a partial delivery may have occurred! Exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join("\n")}"
      announcement.update! status: :delivery_failed
    end
  end

  def process_for_email_delivery announcement, is_reminder
    email_addresses = email_addresses_for announcement
    unless email_addresses.blank?
      @logger.info "Sending email to #{email_addresses.length} unique addresses (in batches of #{@email_batch_size})"

      email_addresses.each_slice(@email_batch_size) do |addresses|
        AnnouncementMailer.announcement_email(announcement, addresses, is_reminder).deliver_later
      end
    end
  end

  def process_for_slack_delivery announcement, is_reminder
    channels = announcement.deliver_to['slack_channels']
    unless channels.blank?
      @logger.info "Sending to slack channels: #{channels}"

      attachment = attachment_for_slack announcement
      icon = icon_for_slack announcement

      if is_reminder
        attachment[:title] = "Reminder: #{attachment[:title]}"
      end

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
        User.active.order(:created_at).pluck(:email)
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
    if announcement.template_data.present?
      output = AnnouncementTemplateFormatterService.format announcement.template_definitions, announcement.template_data
      title = output.title
      text = output.slack
    else
      title = announcement.title
      text = announcement.text
    end

    {
      pretext: "<!channel> #{announcement.level.titleize}:",
      fallback: fallback_text_for_slack(announcement.level, title, text),
      color: color_for_slack(announcement),
      title: Slack::Notifier::Util::Escape.html(title),
      text: Slack::Notifier::Util::Escape.html(text),
      mrkdwn_in: ['text']
    }
  end

  def fallback_text_for_slack level, title, text
    m = []
    m << "[#{level}] #{title}"
    m << text
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
