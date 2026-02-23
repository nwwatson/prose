module ImageOptimizationHelper
  SRCSET_WIDTHS = [ 400, 768, 1536 ].freeze
  OG_IMAGE_WIDTH = 1200
  WEBP_OPTIONS = { format: :webp, saver: { quality: 80 } }.freeze

  def optimized_featured_image_tag(post, **options)
    return unless post.featured_image.attached?

    blob = post.featured_image.blob
    return image_tag(post.featured_image, **options) unless blob.image?

    srcset = SRCSET_WIDTHS.map { |w|
      variant = post.featured_image.variant(resize_to_limit: [ w, nil ], **WEBP_OPTIONS)
      "#{url_for(variant)} #{w}w"
    }.join(", ")

    default_src = url_for(post.featured_image.variant(resize_to_limit: [ 768, nil ], **WEBP_OPTIONS))

    image_tag(
      default_src,
      srcset: srcset,
      sizes: "(max-width: 768px) 100vw, 768px",
      loading: "lazy",
      decoding: "async",
      **options
    )
  end

  def optimized_og_image_url(post)
    return unless post.featured_image.attached?

    blob = post.featured_image.blob
    return rails_storage_proxy_url(post.featured_image) unless blob.image?

    url_for(post.featured_image.variant(resize_to_limit: [ OG_IMAGE_WIDTH, nil ], **WEBP_OPTIONS))
  end

  def optimized_blob_image_tag(blob, in_gallery: false, **options)
    return image_tag(blob.representation(resize_to_limit: in_gallery ? [ 800, 600 ] : [ 1024, 768 ]), **options) unless blob.image?

    widths = in_gallery ? [ 400, 800 ] : [ 400, 768, 1536 ]

    srcset = widths.map { |w|
      variant = blob.variant(resize_to_limit: [ w, nil ], **WEBP_OPTIONS)
      "#{url_for(variant)} #{w}w"
    }.join(", ")

    default_width = in_gallery ? 800 : 768
    default_src = url_for(blob.variant(resize_to_limit: [ default_width, nil ], **WEBP_OPTIONS))

    image_tag(
      default_src,
      srcset: srcset,
      sizes: in_gallery ? "(max-width: 800px) 100vw, 800px" : "(max-width: 768px) 100vw, 768px",
      loading: "lazy",
      decoding: "async",
      **options
    )
  end
end
