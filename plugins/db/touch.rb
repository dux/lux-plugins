module Sequel::Plugins::LuxTouch
  module InstanceMethods
    # touch_on :org_id
    def touch_on name, klass=nil
      klass ||= name.to_s.sub(/_ids?$/, '').classify.constantize

      # get original and new link
      list = column_changes[name].or([]) + [self[name]]
      list
        .flatten
        .xuniq
        .map { |id| klass[id]&.touch }
    end

    def touch
      Lux.current.once 'lux-touch-%s-%s' % [self.class, id] do
        this.update updated_at: 'now()'
      end
   end

    def after_change
      touch if id
      super
    end
  end
end

Sequel::Model.plugin :lux_touch