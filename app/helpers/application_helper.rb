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

  def iiif_thumbnail(document, image_options)
   thumbnail_url = '<img alt="' + document['title'] + '" src="' + document['thumbnail'] + '" />' 
   return thumbnail_url.html_safe
  end


end
