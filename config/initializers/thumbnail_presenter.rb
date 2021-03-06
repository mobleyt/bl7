Blacklight.module_eval do
  class ThumbnailPresenter
    attr_reader :document, :view_context, :view_config

    # @param [SolrDocument] document
    # @param [ActionView::Base] view_context scope for linking and generating urls
    #                                        as well as for invoking "thumbnail_method"
    # @param [Blacklight::Configuration::ViewConfig] view_config
    def initialize(document, view_context, view_config)
      @document = document
      @view_context = view_context
      @view_config = view_config
    end

    ##
    # Does the document have a thumbnail to render?
    #
    # @return [Boolean]
    def exists?
      thumbnail_method.present? ||
        (thumbnail_field && thumbnail_value_from_document(document).present?) ||
        default_thumbnail.present?
    end

    ##
    # Render the thumbnail, if available, for a document and
    # link it to the document record.
    #
    # @param [Hash] image_options to pass to the image tag
    # @param [Hash] url_options to pass to #link_to_document
    # @return [String]
    def thumbnail_tag image_options = {}, url_options = {}
      value = thumbnail_value(image_options)
    #  return value if value.nil? || url_options[:suppress_link]
      return value
   #   view_context.link_to_document document, value, url_options
    end

    private

    delegate :thumbnail_field, :thumbnail_method, :default_thumbnail, to: :view_config

    # @param [Hash] image_options to pass to the image tag
    def thumbnail_value(image_options)
      value = if thumbnail_method
                view_context.send(thumbnail_method, document, image_options)
              elsif thumbnail_field
                image_url = thumbnail_value_from_document(document).gsub("https://rspace.library.cofc.edu/iiif/image/","https://iiif.library.cofc.edu/iiif/2/").gsub("/full/200/0/default.jpg","/full/200,/0/default.jpg")
                view_context.image_tag image_url, image_options if image_url.present?
              end

      value || default_thumbnail_value(image_options)
    end

    def default_thumbnail_value(image_options)
      return unless default_thumbnail

      case default_thumbnail
      when Symbol
        view_context.send(default_thumbnail, document, image_options)
      when Proc
        default_thumbnail.call(document, image_options)
      else
        view_context.image_tag default_thumbnail, image_options
      end
    end

    def thumbnail_value_from_document(document)
      Array(thumbnail_field).lazy.map { |field| document.first(field) }.reject(&:blank?).first
    end
  end
end
