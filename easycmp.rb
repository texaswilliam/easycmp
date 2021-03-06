require 'singleton'

class EasyCmp
  include Singleton

  @opts_default_proc=
    proc do |_,key|
      case key
      when :append
        true
      when :reverse
        false
      else
        nil
      end
    end

  def self.process klass, fields, opts={}
    opts.default_proc=@opts_default_proc
    clear_fields klass unless opts[:append]
    add_fields klass, fields.collect{|field| [field,opts.clone]}
    add_method klass
  end
  def self.add_fields klass, fields
    unless klass.instance_variable_defined? :@easycmp_fields
      klass.instance_variable_set :@easycmp_fields, fields
    else
      #if field exists, merge its old options with the new ones
      klass.instance_variable_set :@easycmp_fields,
          merge_fields(klass.instance_variable_get(:@easycmp_fields), fields)
    end

    return klass
  end
  def self.clear_fields klass
    if klass.instance_variable_defined? :@easycmp_fields
      klass.instance_variable_get(:@easycmp_fields).clear
    end
  end
  def self.add_method klass
    klass.class_exec do
      def <=> oth
        for field,opts in self.class.instance_variable_get :@easycmp_fields
          call=field.to_s.start_with?(?@) ? :instance_variable_get : :send
          unless opts[:reverse]
            result=self.send(call,field)<=>oth.send(call,field)
          else
            result=oth.send(call,field)<=>self.send(call,field)
          end
          return result if result.nonzero?
        end
        return 0
      end
    end
    return klass
  end

  private
  def self.merge_fields a, b
    to_r=[]
    key_overlap=[]

    a.each do |el| field,opts=*el
      if b.assoc field
        key_overlap << field
      else
        to_r << el
      end
    end
    b.each do |el| field,opts=*el
      if key_overlap.include? field
        to_r << [field,a.assoc(field)[1].merge(opts)]
      else
        to_r << el
      end
    end

    return to_r
  end

  module ClassMethods
    private
    def easy_cmp *fields
      return unless fields
      opts=fields.last.is_a?(Hash) ? fields.pop : {}
      return if fields.empty?
      EasyCmp.process self, fields.flatten.collect{|field| field.to_sym}, opts
    end
    def easy_cmp_clear &blk
      EasyCmp.clear_fields self
      define_method(:<=>,&blk) if blk
    end
  end
end

class Object
  extend EasyCmp::ClassMethods
end
