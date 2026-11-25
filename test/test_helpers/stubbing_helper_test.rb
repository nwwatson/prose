require "test_helper"

class StubbingHelperTest < ActiveSupport::TestCase
  class Parent
    def self.inherited_class_method = :parent
    def greeting = :parent
  end

  class Child < Parent
    def self.own_class_method = :real
    def farewell = :real

    private

    def secret = :real
  end

  test "with_singleton_stub restores a method the object defines itself" do
    with_singleton_stub(Child, :own_class_method, -> { :stubbed }) do
      assert_equal :stubbed, Child.own_class_method
    end

    assert_equal :real, Child.own_class_method
    assert Child.singleton_class.method_defined?(:own_class_method, false)
  end

  test "with_singleton_stub removes its stub when the method was inherited" do
    with_singleton_stub(Child, :inherited_class_method, -> { :stubbed }) do
      assert_equal :stubbed, Child.inherited_class_method
    end

    assert_equal :parent, Child.inherited_class_method
    assert_not Child.singleton_class.method_defined?(:inherited_class_method, false)
  end

  test "with_instance_stub restores the original method and its visibility" do
    with_instance_stub(Child, :farewell, -> { :stubbed }) do
      with_instance_stub(Child, :secret, -> { :stubbed }) do
        assert_equal :stubbed, Child.new.farewell
        assert_equal :stubbed, Child.new.send(:secret)
      end
    end

    assert_equal :real, Child.new.farewell
    assert_equal :real, Child.new.send(:secret)
    assert Child.private_method_defined?(:secret, false)
  end

  test "with_instance_stub removes its stub when the method was inherited" do
    with_instance_stub(Child, :greeting, -> { :stubbed }) do
      assert_equal :stubbed, Child.new.greeting
    end

    assert_equal :parent, Child.new.greeting
    assert_not Child.method_defined?(:greeting, false)
  end

  test "stubs are restored when the block raises" do
    assert_raises(RuntimeError) do
      with_instance_stub(Child, :farewell, -> { :stubbed }) { raise "boom" }
    end

    assert_equal :real, Child.new.farewell
  end

  test "with_const replaces and restores a constant" do
    with_const(ReadingListItem, :MAX_ITEMS, 3) do
      assert_equal 3, ReadingListItem::MAX_ITEMS
    end

    assert_equal 500, ReadingListItem::MAX_ITEMS
  end
end
