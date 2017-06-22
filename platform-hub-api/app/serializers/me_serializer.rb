class MeSerializer < UserSerializer

  attribute :global_announcements_unread_count do
    GlobalAnnouncementsService.get_unread_count_for object
  end

end
