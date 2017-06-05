class ContactList

  HASH_RECORD_KEY_POSTFIX = '_contact_list'.freeze
  HASH_RECORD_KEY_POSTFIX_REGEX = /#{HASH_RECORD_KEY_POSTFIX}$/

  class << self
    def find id
      key = "#{id}#{ContactList::HASH_RECORD_KEY_POSTFIX}"
      hash_record = HashRecord.contact_lists.find_or_create_by!(id: key) do |r|
        r.data = { email_addresses: [] }
      end
      ContactList.new hash_record
    end
  end

  # Needed for active_model_serializers to work :(
  alias :read_attribute_for_serialization :send

  attr_reader :hash_record

  def initialize hash_record
    @hash_record = hash_record
  end

  def update params
    @hash_record.update(data: params)
  end

  def id
    @hash_record.id.gsub(ContactList::HASH_RECORD_KEY_POSTFIX_REGEX, '')
  end

  def email_addresses
    @hash_record.data['email_addresses'] || []
  end

  def ==(o)
    o.class == self.class && o.hash_record == self.hash_record
  end

end
