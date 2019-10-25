module ApplicationHelper

  def separate_semicolons options={}
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field

  end

  def line_break_multi options={}
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field
         
    field = ''
    
    options[:value].each do |value|
      field << value + "<br />"
    end
   
    field.html_safe

  end

  def get_parent_document collection_identifier
    
    solr = RSolr.connect :url => 'http://10.7.130.237:8983/solr/rspace/', update_format: :ruby
    solrResponse = solr.get 'select', :params => {:q => 'compoundidentifier:'+collection_identifier + ' AND resourcetype:5', :rows => 1}

    unless solrResponse.nil?
    parent = solrResponse['response']['docs'][0]
    parent_document=SolrDocument.new(parent)
#    parent = []
#    parent["id"] = solrResponse['response']['docs'][0]["id"]
#    parent["title"] = solrResponse['response']['docs'][0]["title"]
    return parent_document
    end

  end


#  def link_to_document(doc, opts={:label=>nil, :counter => nil})
#    opts[:label] ||= blacklight_config.index.show_link.to_sym
#    label = render_document_index_label doc, opts
#    if document['resourcetype'] == "Page"
#    parent = load_page_parent doc
#    id = doc['id']
#    parent_pid = parent['id']
#    link_to label, "/lcdl/catalog/#{parent_pid}?page=#{id}"
#    else
#    link_to label, doc, document_link_params(doc, opts)
#    end
#  end

#  def load_page_parent document
#    id = document['identifier_shortname_facet'].join
#    solr_result = ActiveFedora::SolrService.query("active_fedora_model_ssi:Compound identifier_shortname_facet:#{id}", {:fl=>["id, main_title_tesim"], :rows=>"1"})
#    return solr_result
#  end

#  def load_page_parent_title document
#    id = document['identifier_shortname_facet'].join
#    solr_result = ActiveFedora::SolrService.query("active_fedora_model_ssi:Compound identifier_shortname_facet:#{id}", {:fl=>["id, main_title_tesim"], :rows=>"1"})
#    return solr_result[0]['main_title_tesim'].join
#  end

=begin
  def link_to_document(doc, field_or_opts = nil, opts = { counter: nil })
    label = case field_or_opts
            when NilClass
              index_presenter(doc).label document_show_link_field(doc), opts
            when Hash
              opts = field_or_opts
              index_presenter(doc).label document_show_link_field(doc), opts
            when Proc, Symbol
              Deprecation.warn(self, "passing a #{field_or_opts.class} to link_to_document is deprecated and will be removed in Blacklight 8")
              Deprecation.silence(Blacklight::IndexPresenter) do
                index_presenter(doc).label field_or_opts, opts
              end
            else # String
              field_or_opts
            end

    id = doc['id']
    parent = get_parent_document doc['compoundidentifier'].to_s   
    parent_pid = parent['id'].to_s

    if doc['resourcetype'] == '6'
      link_to label, "/lcdl/catalog/#{parent_pid}?page=#{id}"
    else
      link_to label, url_for_document(doc), document_link_params(doc, opts)
    end

  end
=end

end
