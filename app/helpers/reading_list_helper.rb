module ReadingListHelper
  # Tells the bookmark JS where the reader's list lives. Signed-in readers get
  # their saved ids and the JSON endpoints; everyone else uses localStorage.
  # `key` changes on sign-in/out so the JS knows to drop its in-memory state.
  def reading_list_meta_tag
    if identity_signed_in?
      tag.meta name: "reading-list", content: "account", data: {
        key: "identity-#{current_identity.id}",
        post_ids: current_identity.reading_list_post_ids.to_json,
        items_url: reading_list_items_path,
        import_url: reading_list_import_path
      }
    else
      tag.meta name: "reading-list", content: "local", data: { key: "local" }
    end
  end

  # Rendered inside the cached post card partial, so it must not depend on
  # the current reader — the bookmark controller fills in the saved state.
  def bookmark_button(post)
    tag.button type: "button", hidden: true, class: "bookmark-btn",
      aria: { pressed: "false", label: t("reading_list.bookmark.save") },
      title: t("reading_list.bookmark.save"),
      data: {
        controller: "bookmark",
        action: "bookmark#toggle reading-list:changed@window->bookmark#refresh storage@window->bookmark#refresh",
        bookmark_post_id_value: post.id,
        bookmark_save_label_value: t("reading_list.bookmark.save"),
        bookmark_remove_label_value: t("reading_list.bookmark.remove")
      } do
      bookmark_icon
    end
  end

  private

  def bookmark_icon
    tag.svg class: "bookmark-btn__icon", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": "1.5", "aria-hidden": "true" do
      tag.path "stroke-linecap": "round", "stroke-linejoin": "round",
        d: "M17.593 3.322c1.1.128 1.907 1.077 1.907 2.185V21L12 17.25 4.5 21V5.507c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0z"
    end
  end
end
