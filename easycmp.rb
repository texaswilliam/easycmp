class Module
  def easy_cmp *fields
    return unless fields
    fields=fields.flatten.collect{|field| field.to_sym}
    
    #class_eval '@@easycmp_fields||=[]', __FILE__, __LINE__
    unless instance_variable_defined?(:@easycmp_fields)
      instance_variable_set(:@easycmp_fields,fields)
    else
      instance_variable_set(:@easycmp_fields,
          instance_variable_get(:@easycmp_fields)|fields)
    end
    
    define_method(:<=>) do |oth|
      for field in self.class.instance_variable_get(:@easycmp_fields)
        call=field.to_s.start_with?(?@) ? :instance_variable_get : :send
        result=self.send(call,field)<=>oth.send(call,field)
        return result if result.nonzero?
      end
      0
    end
  end
end
