module BreadcrumbsHelper
  # Ordered breadcrumb trail for a post. Each entry carries :name plus :path and
  # :url variants; the final entry (the post itself) has neither because it is
  # the current page. Shared by breadcrumb_navigation and, in
  # StructuredDataHelper, json_ld_breadcrumb_list.
  def breadcrumb_items(post)
    items = [ { name: "Home", path: root_path, url: root_url } ]

    if post.category.present?
      category = post.category
      items << {
        name: category.name,
        path: category_path(category, slug: category.slug),
        url: category_url(category, slug: category.slug)
      }
    end

    items << { name: post.title }
    items
  end

  def breadcrumb_navigation(post)
    links = breadcrumb_items(post).map do |item|
      if item[:path]
        link_to(item[:name], item[:path], class: "text-ink-blue hover:underline")
      else
        tag.span(item[:name], class: "text-gray-600 dark:text-gray-400")
      end
    end

    safe_join(links, " > ")
  end
end
