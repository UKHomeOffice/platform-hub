class ProjectLookupCacheService

  # IMPORTANT: this is intended to be a short lived cache – it does not update
  # stale items when projects have been updated, so it is recommended to only
  # use this in a single request/response cycle and only when doing lots of
  # project lookups.

  def initialize
    @cache = {}
  end

  def by_id id
    find_and_populate_cache_by_id(id) unless @cache.has_key?(id)
    @cache[id]
  end

  # This is a case insensitive lookup
  def by_shortname value
    downcased_value = value.downcase
    find_and_populate_cache_by_shortname(downcased_value) unless @cache.has_key?(downcased_value)
    @cache[downcased_value]
  end

  private

  def find_and_populate_cache_by_id id
    project = Project.find_by(id: id)
    populate_cache project
  end

  def find_and_populate_cache_by_shortname value
    project = Project.by_shortname(value).first
    populate_cache project
  end

  def populate_cache project
    return if project.blank?

    @cache[project.id] = project
    @cache[project.shortname.downcase] = project
  end

end
