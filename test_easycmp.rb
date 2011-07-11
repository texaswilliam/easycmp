#!/usr/bin/env ruby
require 'test/unit'
require_relative 'easycmp'

class TestEasyCmp < Test::Unit::TestCase
  def setup
    @klass=
      Class.new do
        attr_reader :meth
        easy_cmp :@foo,:meth

        def initialize foo=0,bar=0,meth=0
          @foo=foo
          @bar=bar
          @meth=meth
        end
      end
  end

  def test_standard_case
    #If all variables are equal, we should get 0.
    assert_equal  0, @klass.new       <=>@klass.new
    #If the right-hand operand has our second var larger, we should get -1.
    assert_equal -1, @klass.new       <=>@klass.new(0,0,1)
    #If the left-hand one has our first var larger, though, we get 1 regardless
    #of what the right-hand operand has for the second var.
    assert_equal  1, @klass.new(1,0,0)<=>@klass.new(0,0,1)
  end

  def test_no_extras
    #Since @foo and meth are the only ones being tested, changing @bar should
    #affect nothing.
    assert_equal  1, @klass.new(1,0,0)<=>@klass.new(0,1,1)
    assert_equal  1, @klass.new(1,1,0)<=>@klass.new(0,0,1)
  end
  
  #Let's add @bar to our comparison chain.
  def test_field_append
    @klass.class_eval do easy_cmp :@bar end
    #First, we'll test that :@bar is actually added...
    assert_equal :@bar, @klass.instance_variable_get(:@easycmp_fields).last
    #We'll run the standards to make sure they still work.
    test_standard_case
    #Now, to test @bar...
    assert_equal  1, @klass.new(0,1,0)<=>@klass.new
    assert_equal -1, @klass.new       <=>@klass.new(0,1,0)

    assert_equal  1, @klass.new(1,0,0)<=>@klass.new(0,1,0)
    assert_equal  1, @klass.new(0,0,1)<=>@klass.new(0,1,0)
  end

  #This is to test that when a :sym is given, that obj.sym is called rather than
  #accessing obj's @sym variable.
  def test_methods_are_called
    mod_meth=@klass.new
    assert_equal  0, mod_meth<=>@klass.new
    class << mod_meth
      def meth
        1
      end
    end
    assert_equal  1, mod_meth<=>@klass.new
  end

  def test_flattening
    klass=Class.new do easy_cmp [:one,:two],:three end
    assert_equal [:one,:two,:three],
        klass.instance_variable_get(:@easycmp_fields)
  end

  def test_symbol_conversion
    klass=Class.new do easy_cmp :one,'two',:three end
    assert_equal [:one,:two,:three],
        klass.instance_variable_get(:@easycmp_fields)
  end

  def test_subclass_differentiation
    klass=
      Class.new(@klass) do
        easy_cmp :@new_var
        def initialize new_var=0,foo=0,bar=0,meth=0
          super foo,bar,meth
          @new_var=new_var
        end
      end

    assert_equal  0, klass.new(0,1,1,1)<=>klass.new(0,0,0,0)
    assert_equal  1, klass.new(1,0,0,0)<=>klass.new(0,1,1,1)
    assert_equal -1, klass.new(0,1,1,1)<=>klass.new(1,0,0,0)
  end
end
