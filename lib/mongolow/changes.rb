# encoding: utf-8

module Mongolow
  module Changes
    ##
    # Returns true if field has changed
    #
    def changed?(field)
      if self.respond_to?(field)
        self._old_values[field] != self.send(field)
      end
    end

    ##
    # Returns dirty fields name
    #
    def changed
      self.class.fields.select do |field|
        field[0] != '_' and self._old_values[field] != self.send(field)
      end
    end

    private

    ##
    # Saves values of fields
    #
    def set_old_values
      self._old_values = {}

      self.class.fields.each do |field|
        self._old_values[field] = self.send(field) unless field[0] == '_'
      end
    end
  end
end
