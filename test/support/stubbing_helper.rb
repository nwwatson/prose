# Temporary method and constant replacement (Minitest 6 no longer ships #stub).
#
# Every helper restores exactly what it found: a method the target defined itself
# is put back (with its visibility), and a method it only inherited is removed
# again so the inherited one shows through. Never `remove_method` an application
# method by hand — the real one is then gone for the rest of the worker process.
module StubbingHelper
  # Replaces `object.method_name` (a class method, or a method on one object).
  def with_singleton_stub(object, method_name, implementation)
    swap_method(object.singleton_class, method_name, implementation) { yield }
  end

  # Replaces `klass#method_name` for every instance of `klass`. Inside the
  # implementation `self` is the instance.
  def with_instance_stub(klass, method_name, implementation)
    swap_method(klass, method_name, implementation) { yield }
  end

  # Replaces a constant for the duration of the block.
  def with_const(klass, name, value)
    original = klass.const_get(name)
    klass.send(:remove_const, name)
    klass.const_set(name, value)
    yield
  ensure
    klass.send(:remove_const, name)
    klass.const_set(name, original)
  end

  private

  def swap_method(owner, method_name, implementation)
    visibility = own_method_visibility(owner, method_name)
    original = owner.instance_method(method_name) if visibility
    owner.define_method(method_name, &implementation)
    yield
  ensure
    if visibility
      owner.define_method(method_name, original)
      owner.send(visibility, method_name)
    elsif owner.instance_methods(false).include?(method_name) || owner.private_instance_methods(false).include?(method_name)
      owner.remove_method(method_name)
    end
  end

  def own_method_visibility(owner, method_name)
    if owner.public_method_defined?(method_name, false) then :public
    elsif owner.protected_method_defined?(method_name, false) then :protected
    elsif owner.private_method_defined?(method_name, false) then :private
    end
  end
end
