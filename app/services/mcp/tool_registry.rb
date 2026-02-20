module Mcp
  class ToolRegistry
    def self.all
      [
        Mcp::Tools::ListPosts,
        Mcp::Tools::GetPost,
        Mcp::Tools::CreatePost,
        Mcp::Tools::UpdatePost,
        Mcp::Tools::DeletePost,
        Mcp::Tools::PublishPost,
        Mcp::Tools::SchedulePost,
        Mcp::Tools::UnpublishPost,
        Mcp::Tools::GetSiteInfo,
        Mcp::Tools::UploadAsset,
        Mcp::Tools::SetFeaturedImage,
        Mcp::Tools::ListCategories,
        Mcp::Tools::ListTags,
        Mcp::Tools::CreateTag
      ]
    end
  end
end
