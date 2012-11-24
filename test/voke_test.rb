require "minitest/autorun"

require "bundler/setup"
require "voke"

class TestVoke
  include Voke
end

describe Voke do
  describe ".voke_parse" do
    def voke_parse(*args)
      TestVoke.voke_parse(*args)
    end

    it "parses empty values on empty" do
      result = voke_parse()
      result.must_equal [ nil, [], {} ]
    end

    it "parses the command" do
      result = voke_parse("foo")
      result.must_equal [ "foo", [], {} ]
    end

    it "parses the command and arguments" do
      result = voke_parse("foo", "bar", "world")
      result.must_equal [ "foo", [ "bar", "world" ], {} ]
    end

    it "parses nils in arguments" do
      result = voke_parse("foo", "nil")
      result.must_equal [ "foo", [ nil ], {} ]
    end

    it "parses booleans in arguments" do
      result = voke_parse("foo", "true", "false")
      result.must_equal [ "foo", [ true, false ], {} ]
    end

    it "parses integers in arguments" do
      result = voke_parse("foo", "4", "-3")
      result.must_equal [ "foo", [ 4, -3 ], {} ]
    end

    it "parses floats in arguments" do
      result = voke_parse("foo", "1.2", ".67", "-5.76", "-.5")
      result.must_equal [ "foo", [ 1.2, 0.67, -5.76, -0.5 ], {} ]
    end

    it "parses quoted strings in arguments" do
      result = voke_parse("foo", "'4'", "\"hamburger,fries\"")
      result.must_equal [ "foo", [ "4", "hamburger,fries" ], {} ]
    end

    it "parses arrays in arguments" do
      result = voke_parse("foo", "hamburger,fries", ",")
      result.must_equal [ "foo", [ [ "hamburger", "fries" ], [] ], {} ]
    end

    it "parses values inside arrays in arguments" do
      result = voke_parse("foo", "-4,false,\"nil\",0.76")
      result.must_equal [ "foo", [ [ -4, false, "nil", 0.76 ] ], {} ]
    end

    it "parses the command and options" do
      result = voke_parse("foo", "--hello=world")
      result.must_equal [ "foo", [], { :hello => "world" } ]
    end

    it "parses the command, arguments, and options" do
      result = voke_parse("foo", "--hello=world", "bar", "--apple=fruit")
      result.must_equal [ "foo", [ "bar" ], { :hello => "world", :apple => "fruit" } ]
    end

    it "parses nils in options" do
      result = voke_parse("foo", "--hello=", "--world=nil")
      result.must_equal [ "foo", [], { :hello => nil, :world => nil } ]
    end

    it "parses booleans in options" do
      result = voke_parse("foo", "--hello=true", "--goodbye=false")
      result.must_equal [ "foo", [], { :hello => true, :goodbye => false } ]
    end

    it "parses integers in options" do
      result = voke_parse("foo", "--foo=4", "--bar=-3")
      result.must_equal [ "foo", [], { :foo => 4, :bar => -3 } ]
    end

    it "parses floats in options" do
      result = voke_parse("foo", "--foo=1.2", "--bar=.67", "--hello=-5.76", "--world=-.5")
      result.must_equal [ "foo", [], { :foo => 1.2, :bar => 0.67, :hello => -5.76, :world => -0.5 } ]
    end

    it "parses quoted strings in options" do
      result = voke_parse("foo", "--foo='4'", "--bar=\"hamburger,fries\"")
      result.must_equal [ "foo", [], { :foo => "4", :bar => "hamburger,fries" } ]
    end

    it "parses arrays in options" do
      result = voke_parse("foo", "--foo=hamburger,fries")
      result.must_equal [ "foo", [], { :foo => [ "hamburger", "fries" ] } ]
    end

    it "parses values inside arrays in arguments" do
      result = voke_parse("foo", "--foo=-4,false,\"nil\",0.76")
      result.must_equal [ "foo", [], { :foo => [ -4, false, "nil", 0.76 ] } ]
    end
  end

  describe ".voke_method" do
    # some helpers to make results more obvious
    ARG1 = "arg1"
    ARG2 = "arg2"
    ARG3 = "arg3"
    PARAMS = { :a => 1, :b => 2 }

    def voke_method(method, *args)
      TestVoke.voke_method(method, args, PARAMS)
    end

    describe "zero option definition" do
      class TestVoke
        class << self
          def m0;[];end
        end
      end

      it "calls with no arguments" do
        voke_method(:m0).must_equal []
      end

      it "errors with arguments" do
        lambda { voke_method(:m0, ARG1) }.must_raise ArgumentError
      end
    end

    describe "one option definition" do
      class TestVoke
        class << self
          def m1(a);[a];end
          def m2(a=nil);[a];end
          def n1(*a);a;end
        end
      end

      it "calls with no arguments" do
        voke_method(:m1).must_equal [ PARAMS ]
        voke_method(:m2).must_equal [ PARAMS ]
        voke_method(:n1).must_equal [ PARAMS ]
      end

      it "calls with arguments" do
        voke_method(:m1, ARG1).must_equal [ ARG1 ]
        voke_method(:m2, ARG1).must_equal [ ARG1 ]
        voke_method(:n1, ARG1).must_equal [ ARG1 ]
      end
    end

    describe "two option definition" do
      class TestVoke
        class << self
          def m3(a,b);[a,b];end
          def m4(a,b=nil);[a,b];end
          def m5(a=nil,b);[a,b];end
          def m6(a=nil,b=nil);[a,b];end
          def n2(a,*b);[a]+b;end
          def n3(a=nil,*b);[a]+b;end
          def n4(*a,b);a+[b];end
          #def n5(*a,b=nil);a+[b];end # does not exist
        end
      end

      it "calls with no arguments" do
        lambda { voke_method(:m3) }.must_raise ArgumentError
        lambda { voke_method(:m4) }.must_raise ArgumentError
        voke_method(:m5).must_equal [ nil, PARAMS ]
        voke_method(:m6).must_equal [ PARAMS, nil ] # not ideal
        #voke_method(:m6).must_equal [ nil, PARAMS ]

        lambda { voke_method(:n2) }.must_raise ArgumentError
        voke_method(:n3).must_equal [ PARAMS ]
        voke_method(:n4).must_equal [ PARAMS ]
      end

      it "calls with one argument" do
        voke_method(:m3, ARG1).must_equal [ ARG1, PARAMS ]
        voke_method(:m4, ARG1).must_equal [ ARG1, PARAMS ]
        voke_method(:m5, ARG1).must_equal [ ARG1, PARAMS ]
        voke_method(:m6, ARG1).must_equal [ ARG1, PARAMS ]

        voke_method(:n2, ARG1).must_equal [ ARG1, PARAMS ]
        voke_method(:n3, ARG1).must_equal [ ARG1, PARAMS ]
        voke_method(:n4, ARG1).must_equal [ ARG1, PARAMS ]
      end

      it "calls with two arguments" do
        voke_method(:m3, ARG1, ARG2).must_equal [ ARG1, ARG2 ]
        voke_method(:m4, ARG1, ARG2).must_equal [ ARG1, ARG2 ]
        voke_method(:m5, ARG1, ARG2).must_equal [ ARG1, ARG2 ]
        voke_method(:m6, ARG1, ARG2).must_equal [ ARG1, ARG2 ]

        voke_method(:n2, ARG1, ARG2).must_equal [ ARG1, ARG2 ]
        voke_method(:n3, ARG1, ARG2).must_equal [ ARG1, ARG2 ]
        voke_method(:n4, ARG1, ARG2).must_equal [ ARG1, ARG2 ] # not ideal
      end
    end

    describe "three option definition" do
      class TestVoke
        class << self
          def m7(a,b,c);[a,b,c];end
          def m8(a,b,c=nil);[a,b,c];end
          def m9(a,b=nil,c);[a,b,c];end
          def m10(a,b=nil,c=nil);[a,b,c];end
          def m11(a=nil,b,c);[a,b,c];end
          #def m12(a=nil,b,c=nil);[a,b,c];end # does not exist
          def m13(a=nil,b=nil,c);[a,b,c];end
          def m14(a=nil,b=nil,c=nil);[a,b,c];end
        end
      end

      it "calls with no arguments" do
        lambda { voke_method(:m7) }.must_raise ArgumentError
        lambda { voke_method(:m8) }.must_raise ArgumentError
        lambda { voke_method(:m9) }.must_raise ArgumentError
        lambda { voke_method(:m10) }.must_raise ArgumentError
        lambda { voke_method(:m11) }.must_raise ArgumentError
        voke_method(:m13).must_equal [ nil, nil, PARAMS ]
        voke_method(:m14).must_equal [ PARAMS, nil, nil ] # not ideal
        #voke_method(:m14).must_equal [ nil, nil, PARAMS ]
      end

      it "calls with one argument" do
        lambda { voke_method(:m7, ARG1) }.must_raise ArgumentError
        lambda { voke_method(:m8, ARG1) }.must_raise ArgumentError
        voke_method(:m9, ARG1).must_equal [ ARG1, nil, PARAMS ]
        voke_method(:m10, ARG1).must_equal [ ARG1, PARAMS, nil ] # not ideal
        #voke_method(:m10, ARG1).must_equal [ ARG1, nil, PARAMS ]
        voke_method(:m11, ARG1).must_equal [ nil, ARG1, PARAMS ]
        voke_method(:m13, ARG1).must_equal [ ARG1, nil, PARAMS ]
        voke_method(:m14, ARG1).must_equal [ ARG1, PARAMS, nil ] # not ideal
        #voke_method(:m14, ARG1).must_equal [ ARG1, nil, PARAMS ]
      end

      it "calls with two arguments" do
        voke_method(:m7, ARG1, ARG2).must_equal [ ARG1, ARG2, PARAMS ]
        voke_method(:m8, ARG1, ARG2).must_equal [ ARG1, ARG2, PARAMS ]
        voke_method(:m9, ARG1, ARG2).must_equal [ ARG1, ARG2, PARAMS ]
        voke_method(:m10, ARG1, ARG2).must_equal [ ARG1, ARG2, PARAMS ]
        voke_method(:m11, ARG1, ARG2).must_equal [ ARG1, ARG2, PARAMS ]
        voke_method(:m13, ARG1, ARG2).must_equal [ ARG1, ARG2, PARAMS ]
        voke_method(:m14, ARG1, ARG2).must_equal [ ARG1, ARG2, PARAMS ]
      end

      it "calls with three arguments" do
        voke_method(:m7, ARG1, ARG2, ARG3).must_equal [ ARG1, ARG2, ARG3 ]
        voke_method(:m8, ARG1, ARG2, ARG3).must_equal [ ARG1, ARG2, ARG3 ]
        voke_method(:m9, ARG1, ARG2, ARG3).must_equal [ ARG1, ARG2, ARG3 ]
        voke_method(:m10, ARG1, ARG2, ARG3).must_equal [ ARG1, ARG2, ARG3 ]
        voke_method(:m11, ARG1, ARG2, ARG3).must_equal [ ARG1, ARG2, ARG3 ]
        voke_method(:m13, ARG1, ARG2, ARG3).must_equal [ ARG1, ARG2, ARG3 ]
        voke_method(:m14, ARG1, ARG2, ARG3).must_equal [ ARG1, ARG2, ARG3 ]
      end
    end
  end
end
