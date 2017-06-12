class AnnouncementsProcessorJob < ApplicationJob
  queue_as :announcement_processor

  def self.is_already_queued
    Delayed::Job.where(queue: :announcement_processor).count > 0
  end

  def perform
    AnnouncementsProcessorService.new(
      Rails.application.config.email_max_to_addresses,
      Rails.logger
    ).run
  end
end
