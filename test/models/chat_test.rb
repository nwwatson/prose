require "test_helper"

class ChatTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published_post)
    @user = users(:admin)
  end

  test "belongs to post" do
    chat = Chat.new(post: @post, user: @user, conversation_type: "chat")
    assert_equal @post, chat.post
  end

  test "belongs to user" do
    chat = Chat.new(post: @post, user: @user, conversation_type: "chat")
    assert_equal @user, chat.user
  end

  test "validates conversation_type presence" do
    chat = Chat.new(post: @post, user: @user, conversation_type: "")
    assert_not chat.valid?
    assert_includes chat.errors[:conversation_type], "can't be blank"
  end

  test "validates conversation_type inclusion" do
    chat = Chat.new(post: @post, user: @user, conversation_type: "invalid")
    assert_not chat.valid?
    assert_includes chat.errors[:conversation_type], "is not included in the list"
  end

  test "allows valid conversation types" do
    %w[chat proofread critique brainstorm seo social image].each do |type|
      chat = Chat.new(post: @post, user: @user, conversation_type: type)
      chat.valid?
      assert_not_includes chat.errors[:conversation_type], "is not included in the list",
        "Expected #{type} to be valid"
    end
  end

  test "find_or_create_for creates new chat" do
    assert_difference "Chat.count", 1 do
      Chat.find_or_create_for(post: @post, user: @user, conversation_type: "chat")
    end
  end

  test "find_or_create_for returns existing chat" do
    existing = Chat.create!(post: @post, user: @user, conversation_type: "chat")
    assert_no_difference "Chat.count" do
      found = Chat.find_or_create_for(post: @post, user: @user, conversation_type: "chat")
      assert_equal existing, found
    end
  end

  test "destroying post destroys associated chats" do
    Chat.create!(post: @post, user: @user, conversation_type: "chat")
    assert_difference "Chat.count", -1 do
      @post.destroy
    end
  end
end
