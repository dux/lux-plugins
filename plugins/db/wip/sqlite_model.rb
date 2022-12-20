# # how?
# # * creates parent class that gets dataset from Thread.current
# # * recreate all important Sequel class methods

# # create connection and check schema
# def SqliteModel location
#   db = Sequel.sqlite location

#   SequelTable db, :customers do
#     col :name, String
#     col :email, type(:email)
#     drop :email1
#   end

#   logger = Logger.new(STDOUT)
#   logger.formatter = proc {|_, _, _, msg| 'SQLite ' + msg + $/ }
#   db.loggers.push logger
#   Thread.current[:sqlite_db] = db
# end

# class SqliteModel
#   class << self
#     def db
#       Thread.current[:sqlite_db] ||= SqliteModel(nil)
#     end

#     def inherited klass
#       fields = db.schema(dataset klass.to_s.tableize.to_sym).map(&:first)

#       for el in fields
#         # create static methods from values in schema
#         eval %[
#           #{klass}.class_eval do
#             def #{el}; @values[:#{el}]; end
#             def #{el}= val; @values[:#{el}] = val; end
#           end
#         ]
#       end
#     end

#     def table_name
#       to_s.tableize.to_sym
#     end

#     def dataset name = nil
#       db[name || table_name]
#     end

#     def create data
#       dataset.insert data
#       self
#     end

#     def find id
#       new dataset.where(id: id).first
#     end

#     def last
#       dataset.order(:id).last
#     end

#     def where *args
#       dataset.where *args
#     end

#   end

#   ###

#   def initialize data
#     @values = data
#   end

#   def validate; end
#   def before_destroy; end
#   def after_destroy; end

#   def dataset
#     self.class.dataset.where(id: @values[:id])
#   end

#   def save
#     dataset.update @values.except(:id)
#     self
#   end

#   def update data
#     dataset.update data
#     @values = @values.merge data
#     self
#   end

#   def destroy
#     dataset.destroy
#   end

#   def to_h
#     @values
#   end

#   def attributes
#     @values
#   end
# end

# class Customer < SqliteModel
# end

# Customer.create name: 'Dux mem', email: 'dux@net.hr'
# rr Customer.last.to_h

# SqliteModel 'tmp/t3.sqlite'

# Customer.create name: 'Dux disk', email: 'dux@net.hr'

# c1 = Customer.find(1)
# rr c1.to_h
# c1.email += 'a'
# rr c1.email
# c1.save
# c1.update name: 'Name %s' % Time.now

# rr Customer.last.to_h

