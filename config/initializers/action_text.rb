Rails.application.config.after_initialize do
  ActionText::ContentHelper.allowed_tags = ActionText::ContentHelper.sanitizer.class.allowed_tags +
    [ ActionText::Attachment.tag_name, "figure", "figcaption", "iframe" ]

  ActionText::ContentHelper.allowed_attributes = ActionText::ContentHelper.sanitizer.class.allowed_attributes +
    ActionText::Attachment::ATTRIBUTES +
    %w[frameborder allowfullscreen allow loading]
end
