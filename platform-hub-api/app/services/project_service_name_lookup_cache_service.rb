class ProjectServiceNameLookupCacheService

  # IMPORTANT: this is intended to be a short lived cache – it does not update
  # stale items when services have been updated, so it is recommended to only
  # use this in a single request/response cycle and only when doing lots of
  # service name lookups.

  def initialize
    # Set up with initial data
    @cache = Service.all.pluck(:id, :name).each_with_object({}) do |(id, name), obj|
      obj[id] = name
    end
  end

  def by_id service_id
    find_and_populate_cache(service_id) unless @cache.has_key?(service_id)
    @cache[service_id]
  end

  private

  def find_and_populate_cache service_id
    name = Service.where(id: service_id).pluck(:name).first
    if name.present?
      @cache[service_id] = name
    end
  end

end
