# frozen_string_literal: true
class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller

  include BlacklightRangeLimit::ControllerOverride

  include Blacklight::Catalog

  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
#    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'edismax'
    config.advanced_search = {
      :form_solr_parameters => {
        "facet.field" => ["mediatype_facet", "contribinst_facet"],
        "facet.limit" => -1, # return all facet values
        "facet.sort" => "index"}, # sort by byte order of values
      :form_facet_partial => "advanced_search_facets_as_select"
    }

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response


    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters

    config.default_solr_params = {
      rows: 10,
      qt: '/select',
      fq: '-resourcetype:6'
    }

    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'
    #config.document_solr_path = 'get'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    # solr field configuration for search results/index views
    config.index.title_field = 'title'
    config.index.display_type_field = 'resourcetype'
    config.show.display_type_field = 'resourcetype'
    config.index.thumbnail_field = 'thumbnail'
    config.index.thumbnail_method = 'iiif_thumbnail'
#    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

#    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
#    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)
#    config.add_show_tools_partial(:more_like_this_document)

#    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # solr field configuration for document/show views
    #config.show.title_field = 'title_tsim'
    #config.show.display_type_field = 'format'
    #config.show.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

#    config.add_facet_field 'exclude-pages', label: 'Exclude Page Results'
    config.add_facet_field 'collection_titleInfo_title_facet', label: 'Collection', limit: 10
    config.add_facet_field 'contribinst_facet', label: 'Contributing Institution', limit: 10
    config.add_facet_field 'mediatype_facet', label: 'Media Type', limit: 10
    config.add_facet_field 'subject_topic_facet', label: 'Subject (Topic)', limit: 10
    config.add_facet_field 'subject_geographic_facet', label: 'Subject (Geographic)', limit: 10
    config.add_facet_field 'date_facet_facet', label: 'Date', limit: 10
    config.add_facet_field 'seriesinfo_seriestitle_facet', label: 'Series', show: false
#    config.add_facet_field 'seriesinfo_subseriestitle_facet', label: 'Subseries', show: false
    config.add_facet_field 'daterange', label: 'Date Range (beta)', range: true
#    config.add_facet_field 'pub_date_ssim', label: 'Publication Year', single: true
#    config.add_facet_field 'subject_ssim', label: 'Topic', limit: 20, index_range: 'A'..'Z'
#    config.add_facet_field 'language_ssim', label: 'Language', limit: true
#    config.add_facet_field 'lc_1letter_ssim', label: 'Call Number'
#    config.add_facet_field 'subject_geo_ssim', label: 'Region'
#    config.add_facet_field 'subject_era_ssim', label: 'Era'

#    config.add_facet_field 'example_pivot_field', label: 'Pivot Field', :pivot => ['format', 'language_ssim']

#    config.add_facet_field 'example_query_facet_field', label: 'Publish Date', :query => {
#       :years_5 => { label: 'within 5 Years', fq: "pub_date_ssim:[#{Time.zone.now.year - 5 } TO *]" },
#       :years_10 => { label: 'within 10 Years', fq: "pub_date_ssim:[#{Time.zone.now.year - 10 } TO *]" },
#       :years_25 => { label: 'within 25 Years', fq: "pub_date_ssim:[#{Time.zone.now.year - 25 } TO *]" }
#    }


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
#    config.add_index_field 'title', label: 'Title'
    config.add_index_field 'date', label: 'Date'
    config.add_index_field 'description', label: 'Description'
 
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'title', label: 'Title'
    config.add_show_field 'date', label: 'Date'
    config.add_show_field 'interviewer', label: 'Interviewer'
    config.add_show_field 'interviewee', label: 'Interviewee'
    config.add_show_field 'creatornamecorporate', label: 'Creator (Corporate)'
    config.add_show_field 'creatornamepersonal', label: 'Creator (Personal)'
    config.add_show_field 'contributor', label: 'Contributor'
    config.add_show_field 'description', label: 'Description'
    config.add_show_field 'collectiontitle', label: 'Collection Title', link_to_facet: 'collection_titleInfo_title_facet'
    config.add_show_field 'contribinst', link_to_facet: 'contribinst-facet', label: 'Contributing Institution'
    config.add_show_field 'mediatype', label: 'Media Type', link_to_facet: 'mediatype_facet'
    config.add_show_field 'alternatetitle', label: 'Alternate Title'
    config.add_show_field 'subtitle', label: 'Subtitle'
    config.add_show_field 'abstract', label: 'Abstract'
    config.add_show_field 'note', label: 'Note'
    config.add_show_field 'biographicalnote', label: 'Biographical Note'
    config.add_show_field 'creatornote', label: 'Creator Note'
    config.add_show_field 'collectionnote', label: 'Collection Note'
    config.add_show_field 'locationrecord', label: 'Location Recorded'
    config.add_show_field 'conditionevaluationn', label: 'Condition'
    config.add_show_field 'extent', label: 'Dimensions'
    config.add_show_field 'seriestitle', label: 'Series', link_to_facet: 'seriesinfo_seriestitle_facet'
    config.add_show_field 'subseriestitle', label: 'Sub-Series', link_to_facet: 'subseriestitle-facet'
    config.add_show_field 'photoid', label: 'Photo ID Number'
    config.add_show_field 'portfoliotitle', label: 'Original Portfolio'
    config.add_show_field 'portfolionumber', label: 'Portfolio Number'
    config.add_show_field 'foldernumber', label: 'Folder Number'
    config.add_show_field 'region', label: 'Region'
    config.add_show_field 'physdesc_note', label: 'Material Type'
    config.add_show_field 'originalformat', label: 'Format of Original'
    config.add_show_field 'typeaat', label: 'Type (AAT)'
    config.add_show_field 'typedcmi', label: 'Type (DCMI)'
    config.add_show_field 'citation', label: 'Preferred Citation'
    config.add_show_field 'subject-name', label: 'Personal or Corporate Subject', helper_method: 'line_break_multi'
    config.add_show_field 'subject-topical', label: 'Topical Subject', link_to_facet: 'subject_topic_facet'
    config.add_show_field 'subject-geographic', label: 'Geographic Subject', link_to_facet: 'subject_geographic_facet'
    config.add_show_field 'subject-county', label: 'S.C. County'
    config.add_show_field 'language', label: 'Language'
    config.add_show_field 'resourcelocator', label: 'Shelving Locator', helper_method: 'line_break_multi'
    config.add_show_field 'datedigital', label: 'Date Digital'
    config.add_show_field 'digispec', label: 'Digitization Specifications'
    config.add_show_field 'typeimt', label: 'Internet Media Type'
    config.add_show_field 'format', label: 'Format'
    config.add_show_field 'rights', label: 'Copyright Status Statement'
    config.add_show_field 'accessstatement', label: 'Access Statement'
    config.add_show_field 'accessnote', label: 'Access Information'
    config.add_show_field 'rspace-id', label: 'Admin ID'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    #config.add_search_field 'all_fields', label: 'All Fields'


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.


    config.add_search_field 'all_fields', label: 'Simple Search'

    config.add_search_field('PageContentSearch') do |field|
      field.solr_parameters = {
        fq: ''
      }
    end

    config.add_search_field('Title Search') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = {
        qf: '${title_qf}',
        pf: '${title_pf}'
      }
    end

    config.add_search_field('Creator Search') do |field|
      field.solr_parameters = {
        qf: '${creator_qf}',
        pf: '${creator_pf}'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('Subject Search') do |field|
      field.solr_parameters = {
        qf: '${subject_qf}',
        pf: '${subject_pf}'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title asc', label: 'Relevance'
    config.add_sort_field 'title asc', label: 'Title'
    config.add_sort_field 'daterange desc', label: 'Date (Newest)'
    config.add_sort_field 'daterange asc', label: 'Date (Oldest)'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
  end
end
