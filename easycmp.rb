module EasyCmp
  class_variable_set(:@@fields,Hash.new)

  def fields
    @@fields
  end
  
  module ClassMethods
    def easy_cmp *fields
      EasyCmp.fields[self]=fields
      module_eval %Q{
        def <=> oth
          for field in EasyCmp.fields[self.class]
            call=field.to_s.start_with?(?@) ? :instance_variable_get : :send
            result=self.send(call,field)<=>oth.send(call,field)
            return result if result.nonzero?
          end
          0
        end
      },__FILE__,__LINE__
    end
  end
end

class Object
  include EasyCmp
  extend EasyCmp::ClassMethods
end
