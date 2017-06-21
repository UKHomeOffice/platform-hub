class CreateContactLists < ActiveRecord::Migration[5.0]

  def up
    create_table :contact_lists, id: :string do |t|
      t.string :email_addresses, array: true

      t.timestamps
    end

    migrate_existing_data
  end

  def down
    drop_table :contact_lists
  end

  private

  KEY_REGEX = /(.+)_contact_list/

  def migrate_existing_data
    puts 'Migrating any existing contact list HashRecord entries to the new contact_lists table'
    keys = HashRecord.pluck :id
    keys.each do |k|
      match = KEY_REGEX.match k
      if match
        HashRecord.transaction do
          hr = HashRecord.find k
          ContactList.create!(
            id: match[1],
            email_addresses: hr.data['email_addresses']
          )
          hr.destroy!
        end
      end
    end
  end

end
