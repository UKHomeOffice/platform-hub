module GlobalAnnouncementsService

  def self.get_announcements
    scope
  end

  def self.get_unread_count_for user
    scope.unread_by(user).count
  end

  def self.mark_all_read_for user
    scope.mark_as_read! :all, :for => user
  end


  def self.scope
    Announcement.global.published
  end
  private_class_method :scope

end
