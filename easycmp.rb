class Module
  def easy_cmp *fields
    @@easycmp_fields||=[]
    @@easycmp_fields|=fields
    define_method(:<=>) do |oth|
      for field in @@easycmp_fields
        call=field.to_s.start_with?(?@) ? :instance_variable_get : :send
        result=self.send(call,field)<=>oth.send(call,field)
        return result if result.nonzero?
      end
      0
    end
  end
end
