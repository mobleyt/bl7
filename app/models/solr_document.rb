# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  
  def more_like_this

    if self.id.include? "lcdl"
      id = self.id.gsub("lcdl:","lcdl\\:")
    else
      id = self.id
    end

    solr = RSolr.connect :url => 'http://10.7.130.237:8983/solr/rspace/'
    solrMLTResponse = solr.get 'mlt', :params => {:q => 'id:'+id, :'mlt.fl' => 'subject-topical,title', :rows => 5}
    
    unless solrMLTResponse.empty?
    list=[]
    solrMLTResponse['response']['docs'].each { |doc|
      doc=SolrDocument.new(doc)
      list.push(doc)
    }
    return list;
    end
  end

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
end
