module Api
  module V1
    class SiteController < Api::V1::BaseController
      def show
        settings = SiteSetting.current
        category_post_counts = Category.post_counts
        tag_post_counts = Tag.post_counts

        render json: {
          site_name: settings.site_name,
          site_description: settings.site_description,
          categories: Category.ordered.map { |c| { name: c.name, slug: c.slug, post_count: category_post_counts.fetch(c.id, 0) } },
          tags: Tag.all.map { |t| { name: t.name, slug: t.slug, post_count: tag_post_counts.fetch(t.id, 0) } },
          post_counts: {
            total: Post.count,
            published: Post.published.count,
            draft: Post.draft.count,
            scheduled: Post.scheduled.count
          }
        }
      end
    end
  end
end
