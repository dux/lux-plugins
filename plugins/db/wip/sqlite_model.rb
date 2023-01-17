# # how?
# # * creates parent class that gets dataset from Thread.current
# # * recreate all important Sequel class methods

# EXAMPLE ON THE END
# REMEMBER that you have to migrate schema on db init for sqlite

class SqliteModel
  cattr :db_conn, class: true

  class << self
    def logger target = nil
      Logger.new(target || STDOUT).tap do |l|
        l.formatter = proc {|_, _, _, msg| 'SQLite ' + msg + $/ }
      end
    end

    def db &block
      if block
        cattr.db_conn = block
      else
        cattr.db_conn
      end
    end

    def table name = nil, &block
      name ||= self.to_s.split('::').last.tableize
      SequelTable db_conn, name, &block
    end

    def inherited klass
      if klass.db
        fields = klass.db.schema(table_name(klass)).map(&:first) rescue []

        for el in fields
          # create static methods from values in schema
          eval %[
            #{klass}.class_eval do
              def #{el}; @values[:#{el}]; end
              def #{el}= val; @values[:#{el}] = val; end
            end
          ]
        end
      end
    end

    def table_name klass = nil
      (klass || to_s).to_s.split('::').last.tableize.to_sym
    end

    def dataset name = nil
      self.db[name || table_name]
    end

    def create data = {}
      new(data).save
    end

    def find id
      new dataset.where(id: id).first
    end

    def last
      new dataset.order(:id).last
    end

    def where *args
      dataset.where *args
    end

    def order str
      dataset.order(str.class == String ? Sequel.lit(str) : str)
    end

    def fetch opts = {}
      out = yield(self)
      Paginate out, **opts.merge(klass: self)
    end

    def fetch! opts = {}, &block
      out = instance_exec(&block)
      Paginate out, **opts.merge(klass: self)
    end
  end

  ###

  def initialize data = {}
    @values = (data || {}).to_hwia
  end

  def validate; end
  def before_destroy; end
  def after_destroy; end

  def dataset
    self.class.dataset.where(id: @values[:id])
  end

  def save
    validate

    copy = @values.map do |k, v|
      v = v.to_json if v.class == Hash
      [k, v]
    end.to_h

    if @values[:id]
      copy[:updated_at] = Time.now if respond_to?(:updated_at)
      copy[:updated_by] = User.current.id if respond_to?(:updated_by)
      dataset.update copy.except(:id)
    else
      copy[:created_at] = Time.now if respond_to?(:created_at)
      copy[:created_by] = User.current.id if respond_to?(:created_by)
      @values[:id] = dataset.insert copy
    end

    self
  end

  def update data
    dataset.update data
    @values = @values.merge data
    self
  end

  def destroy
    dataset.destroy
  end

  def to_h
    @values.to_h
  end
  alias :attributes :to_h
end

# def SimpleFeedback
#   Lux.config[:simple_feedback_sqlite] ||= begin
#     Sequel.sqlite('./db/sqlite/simple_feedback.sqlite').tap do |db|
#       db.loggers.push SqliteModel.logger

#       SequelTable db, :feedbacks do
#         col :name, String
#         col :email, String
#       end
#     end
#   end
# end

# class SimpleFeedback < SqliteModel
#   db { SimpleFeedback() }
# end

# class SimpleFeedback
#   class Feedback < SimpleFeedback
#   end
# end

# f = SimpleFeedback::Feedback.new
# f.name = 'Dux %s' % Time.now
# f.email = '%s@foo.bar' % rand
# f.save

# rr SimpleFeedback::Feedback.dataset.all
