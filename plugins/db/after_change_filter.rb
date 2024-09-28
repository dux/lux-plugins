# call after_change to execute every time object changes
# (ideal for clearing caches)

module Sequel::Plugins::LuxAfterChange
  module InstanceMethods
    # after create, update and destroy
    def after_change
    end

    # only after create or destroy (used for counts mostly)
    def after_create_or_destroy
    end

    def after_create
      after_create_or_destroy
      super
    end

    def after_save
      after_change
      super
    end

    def after_destroy
      after_change
      after_create_or_destroy
      super
    end
  end

  module ClassMethods
    [
      :validate,
      :before_create,
      :before_save,
      :after_create,
      :after_save,
      :before_destroy,
      :after_destroy,
      :after_change,
      :after_create_or_destroy
    ].each do |el|
      eval %[
        def #{el} &block
          define_method :#{el} do
            instance_exec &block
            super()
          end
        end
      ]
    end
  end
end

# Sequel::Model.plugin :lux_after_change
