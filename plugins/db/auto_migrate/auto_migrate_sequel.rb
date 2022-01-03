# Originaly made for sqlite

# class Sequel::Postgres::Database
#   # Auto adds tables and colums. Will not delete, will not modify
#   #
#   #   DB_LOG.auto_migrate :custom_links_log do
#   #     col :name
#   #     col :foo, null: true
#   #     col :bar, null: true
#   #     col :baz, null: true
#   #     col :created_at, Time
#   #   end
#   def auto_migrate table, &block
#     SequelAutoMigrate.run self, table, &block
#   end
# end

# class SequelAutoMigrate
#   class << self
#     def run db, table, &block
#       am = new db, table
#       am.instance_exec &block
#     end
#   end

#   ###

#   def initialize db, table
#     @db    = db
#     @table = table

#     unless db.tables.include?(@table)
#       @db.create_table @table do
#         primary_key :id
#         Time :created_at
#       end
#     end
#   end

#   def schema
#     Hash[@db.schema(@table)]
#   end

#   def col name, type = nil, opts = {}
#     if type.is_a?(Hash)
#       opts = type
#       type = String
#     end

#     unless schema[name]
#       table = @table
#       @db.alter_table @table do
#         add_column name, type, opts
#         puts '* automigrate add column: %s' % [table, name, type].join(':')
#       end
#     end
#   end
# end
