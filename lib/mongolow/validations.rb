# encoding: utf-8

module Mongolow
  module Validations
    def presence_of(field_name, options={})
      unless self.send(field_name)
        self.add_error(field_name, 'blank' || options[:message])
      end
    end

    def inclusion_of(field_name, values, options={})
      unless not self.send(field_name) or values.include?(self.send(field_name))
        self.add_error(field_name, 'inclusion' || options[:message])
      end
    end

    def uniquenes_of(field_name, options={})
      query = {field_name => self.send(field_name), _id: {'$ne' => self._id}}

      if self.changed?(field_name) and self.class.find(query).first
        self.add_error(field_name, 'taken' || options[:message])
      end
    end

    def match_of(field_name, value, options={})
      unless self.send(field_name) and self.send(field_name).match(value)
        self.add_error(field_name, 'match' || options[:message])
      end
    end

    def add_error(field_name, error)
      self._errors[field_name.to_s] = ((self._errors[field_name.to_s] || []) << error)
    end
  end
end
