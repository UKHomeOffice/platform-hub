module HelpSearchStatusService

  KEY = 'help_search_status'

  def self.reindex_started forced
    update! do |status|
      status['reindexing'] = true
      status['forced_reindexing'] = !!forced
    end
  end

  def self.reindex_finished
    update! do |status|
      status['reindexing'] = false
      status['forced_reindexing'] = false
    end
  end

  def self.status
    get_hash_record.data
  end

  private_class_method def self.get_hash_record
    HashRecord.find_or_create_by!(id: KEY, scope: 'general') do |r|
      r.data = {
        'reindexing' => false,
        'forced_reindexing' => false
      }
    end
  end

  private_class_method def self.update!
    record = get_hash_record

    record.with_lock do
      yield record.data
      record.save!
    end
  end

end
