module EasyCmp
  def self.add_fields klass, *fields
    return unless fields
    
    fields.flatten!
    fields.collect!{|field| field.to_sym}

    klass.class_exec fields do |fields|
      unless instance_variable_defined?(:@easycmp_fields)
        instance_variable_set(:@easycmp_fields,fields)
      else
        instance_variable_set(:@easycmp_fields,
            instance_variable_get(:@easycmp_fields)|fields)
      end
    end
    return klass
  end
  def self.add_method klass
    klass.class_exec do
      def <=> oth
        for field in self.class.instance_variable_get(:@easycmp_fields)
          call=field.to_s.start_with?(?@) ? :instance_variable_get : :send
          result=self.send(call,field)<=>oth.send(call,field)
          return result if result.nonzero?
        end
        return 0
      end
    end
    return klass
  end

  module ClassMethods
    private
    def easy_cmp *fields
      EasyCmp.add_fields self, fields
      EasyCmp.add_method self
    end
  end
end

class Object
  extend EasyCmp::ClassMethods
end
