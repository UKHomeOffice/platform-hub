class AddEmailUniqueConstraintToUsers < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      alter table users
        add constraint user_email unique (email);
    SQL
  end

  def down
    execute <<-SQL
      alter table users
        drop constraint if exists user_email;
    SQL
  end

end
