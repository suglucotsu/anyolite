module Anyolite
  # Module for specific casts of Crystal values into mruby values
  module RbCast
    # Explicit return methods

    def self.return_nil
      return MrbInternal.get_nil_value
    end

    def self.return_true
      return MrbInternal.get_true_value
    end

    def self.return_false
      return MrbInternal.get_false_value
    end

    def self.return_fixnum(value)
      return MrbInternal.get_fixnum_value(value)
    end

    def self.return_bool(value)
      return MrbInternal.get_bool_value(value ? 1 : 0)
    end

    def self.return_float(mrb, value)
      return MrbInternal.get_float_value(mrb, value)
    end

    def self.return_string(mrb, value)
      return MrbInternal.get_string_value(mrb, value)
    end

    # Implicit return methods

    def self.return_value(mrb : MrbInternal::MrbState*, value : Nil)
      self.return_nil
    end

    def self.return_value(mrb : MrbInternal::MrbState*, value : Bool)
      value ? self.return_true : return_false
    end

    def self.return_value(mrb : MrbInternal::MrbState*, value : Int)
      self.return_fixnum(value)
    end

    def self.return_value(mrb : MrbInternal::MrbState*, value : Float)
      self.return_float(mrb, value)
    end

    def self.return_value(mrb : MrbInternal::MrbState*, value : String)
      self.return_string(mrb, value)
    end

    def self.return_value(mrb : MrbInternal::MrbState*, value : Struct)
      ruby_class = RbClassCache.get(typeof(value))

      destructor = RbTypeCache.destructor_method(typeof(value))

      ptr = Pointer(typeof(value)).malloc(size: 1, value: value)

      new_ruby_object = MrbInternal.new_empty_object(mrb, ruby_class, ptr.as(Void*), RbTypeCache.register(typeof(value), destructor))

      struct_wrapper = Macro.convert_from_ruby_struct(mrb, new_ruby_object, typeof(value))
      struct_wrapper.value = StructWrapper(typeof(value)).new(value)

      RbRefTable.add(RbRefTable.get_object_id(struct_wrapper.value), ptr.as(Void*))

      return new_ruby_object
    end

    def self.return_value(mrb : MrbInternal::MrbState*, value : Object)
      ruby_class = RbClassCache.get(typeof(value))

      destructor = RbTypeCache.destructor_method(typeof(value))

      ptr = Pointer(typeof(value)).malloc(size: 1, value: value)

      new_ruby_object = MrbInternal.new_empty_object(mrb, ruby_class, ptr.as(Void*), RbTypeCache.register(typeof(value), destructor))

      Macro.convert_from_ruby_object(mrb, new_ruby_object, typeof(value)).value = value

      RbRefTable.add(RbRefTable.get_object_id(value), ptr.as(Void*))

      return new_ruby_object
    end

    # Class check methods

    def self.check_for_undef(value : MrbInternal::MrbValue)
      MrbInternal.check_mrb_undef(value) != 0
    end

    def self.check_for_nil(value : MrbInternal::MrbValue)
      MrbInternal.check_mrb_nil(value) != 0
    end

    def self.check_for_true(value : MrbInternal::MrbValue)
      MrbInternal.check_mrb_true(value) != 0
    end

    def self.check_for_false(value : MrbInternal::MrbValue)
      MrbInternal.check_mrb_false(value) != 0
    end

    def self.check_for_bool(value : MrbInternal::MrbValue)
      RbCast.check_for_true(value) || RbCast.check_for_false(value)
    end

    def self.check_for_fixnum(value : MrbInternal::MrbValue)
      MrbInternal.check_mrb_fixnum(value) != 0
    end

    def self.check_for_float(value : MrbInternal::MrbValue)
      MrbInternal.check_mrb_float(value) != 0
    end

    def self.check_for_string(value : MrbInternal::MrbValue)
      MrbInternal.check_mrb_string(value) != 0
    end

    def self.check_for_data(value : MrbInternal::MrbValue)
      MrbInternal.check_mrb_data(value) != 0
    end

    def self.cast_to_nil(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
      if RbCast.check_for_nil(value)
        nil
      else
        MrbInternal.mrb_raise_argument_error(mrb, "Could not cast #{value} to Nil.")
        nil
      end
    end

    def self.cast_to_bool(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
      if RbCast.check_for_true(value)
        true
      elsif RbCast.check_for_false(value)
        false
      else
        MrbInternal.mrb_raise_argument_error(mrb, "Could not cast #{value} to Bool.")
        false
      end
    end

    def self.cast_to_int(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
      if RbCast.check_for_fixnum(value)
        MrbInternal.get_mrb_fixnum(value)
      else
        MrbInternal.mrb_raise_argument_error(mrb, "Could not cast #{value} to Int.")
        0
      end
    end

    def self.cast_to_float(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
      if RbCast.check_for_float(value)
        MrbInternal.get_mrb_float(value)
      else
        MrbInternal.mrb_raise_argument_error(mrb, "Could not cast #{value} to Float.")
        0.0
      end
    end

    def self.cast_to_string(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
      if RbCast.check_for_string(value)
        String.new(MrbInternal.get_mrb_string(mrb, value))
      else
        MrbInternal.mrb_raise_argument_error(mrb, "Could not cast #{value} to String.")
        ""
      end
    end

    macro check_custom_type(mrb, value, crystal_type)
      MrbInternal.mrb_obj_is_kind_of({{mrb}}, {{value}}, Anyolite::RbClassCache.get({{crystal_type}})) != 0
    end

    def self.is_undef?(value) # Excludes non-MrbValue types as well
      if value.is_a?(MrbInternal::MrbValue)
        Anyolite::RbCast.check_for_undef(value)
      else
        false
      end
    end

    # TODO: Conversions of other objects like arrays and hashes
  end
end