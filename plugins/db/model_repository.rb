class ModelRepository
  attr_reader :model

  def initialize model
    @model  = model
    @is_new = @model.id ? false : false
    @model.instance_variable_set :@_repository_call, true
  end

  def is_new?
    @is_new
  end

  def errors
    @model.errors
  end

  def validate; end
  def before; end
  def before_create; end
  def before_destroy; end
  def after; end
  def after_create; end
  def after_destroy; end

  def update fields = {}, run_hooks=true, &block
    fields.each do |key, val|
      @model.send('%s=' % key, val)
    end

    save run_hooks, &block
  end

  def save run_hooks=true
    self.validate
    @model.validate

    if @model.valid?
      if run_hooks
        self.before_create
        self.before
      end

      @model.save validate: false

      if run_hooks
        self.after_create if is_new?
        self.after
      end
    elsif block_given?
      @model.errors.keys.each do |key|
        yield key, @model.errors[key]
      end
    end

    @model
  end

  def destroy run_hooks=true
    self.before_destroy if run_hooks

    @model.destroy.tap do |result|
      self.after_destroy if run_hooks
    end
  end
end

def ModelRepository.patch_application_model
  ApplicationModel.class_eval do
    def repository
      @repository ||= ('%sRepository' % self.class).constantize.new(self)
    end

    def update *args, &block
      repository.update *args, &block
    end

    def create fields = {}
      repository.update fields
    end

    def save *args, &block
      if @_repository_call
        super
      else
        repository.save *args, &block
      end
    end

    def delete
      unless caller[0].include?('lib/sequel/model/base.rb')
        raise 'delete is not allowed, please use destroy'
      end

      super
    end

    def destroy *args, &block
      if @_repository_call
        super
      else
        repository.destroy *args, &block
      end
    end

    def self.method_added name
      if %i(validate before before_create after after_create before_destroy after_destroy).include?(name)
        puts %[Method "#{name}" not allowed in model "#{self}", please define it in "#{self}Repository".].red
        puts '* %s' % caller[0]
        exit
      end

      super
    end
  end
end
