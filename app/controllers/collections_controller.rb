class CollectionsController < ApplicationController


require 'open-uri'
require 'json'
require 'pp'

def compound_manifest

identifier = params[:identifier]
coll_identifier = params[:collidentifier]

if File.file?("/webapps/bl7/manifests/compound/#{identifier}.json")

manifest = File.read("/webapps/bl7/manifests/compound/#{identifier}.json")
render :json => manifest

else

compound_iiif = "http://rspace.library.cofc.edu/iiif/#{identifier}/manifest"

# Actually fetch the contents of the remote URL as a String.
buffer = open(compound_iiif).read

# Convert the JSON response to hash
compound = JSON.parse(buffer)
compound.delete("sequences")

# Clear out empty metadata fields that RS includes for some reason
multi["metadata"].delete_if { |h| h["value"] == "" }
multi["metadata"].delete_if { |h| h["value"] == [] }

#Get page list from Solr query 
page_list = "http://10.7.130.237:8983/solr/rspace/select?fl=iiif,pageorder&q=collectionidentifier:%22#{coll_identifier}%22%20AND%20resourcetype:6&rows=5000&wt=json"
page_buffer = open(page_list).read
pages = JSON.parse(page_buffer)
pages = pages["response"]["docs"]

#Order page list by page order and strip down to array for iteration
order = {}
pages.each do |page| order[page["pageorder"]]= page["iiif"] end
neworder = order.sort_by { |k,v| k.to_i}
list = []
neworder.each do |o| list.push(o[1]) end

#set array to hold all canvases
sequences = {}
canvases = []

#call each page manifest, isolate sequence, then add canvas to array
list.each do |l|
  list_buffer = open("http://rspace.library.cofc.edu/iiif/#{l}/manifest").read
  page_iiif = JSON.parse(list_buffer)
  
  page_sequences = page_iiif["sequences"]

#add otherContent for annotation list
  other_content = []
  inner_content = {}
  inner_content["@context"] = "//iiif.io/api/presentation/2/context.json"
  inner_content["@id"] = "https://beta.lcdl.library.cofc.edu/lcdl/collections/annotation?iiif_identifier=#{l}"
  inner_content["@type"] = "sc:AnnotationList"
  
  other_content.push(inner_content)
   
  page_sequences[0]["canvases"][0]["otherContent"] = other_content 

  page_sequences.each do |sequence| 
    canvases.push(sequence["canvases"][0]) 
  end
end

wrap = []

sequences["@id"] = "http://rspace.library.cofc.edu/iiif/#{coll_identifier}/sequence/normal"
sequences["@type"] = "sc:Sequence"
sequences["label"] = "Default order"
sequences["canvases"] = canvases

wrap.push(sequences)

compound["sequences"] = wrap

File.open("/webapps/bl7/manifests/compound/#{identifier}.json","w") do |f|
  f.write(JSON.pretty_generate(compound))
end

render json: compound

end #end else
end #end generate compound method


def multi_manifest

identifier = params[:iiifidentifier]
rspaceid = params[:rspaceid]

if File.file?("/manifests/multi/#{identifier}.json")

manifest = File.read("/manifests/multi/#{identifier}.json")
render :json => manifest

else

manifest = "http://rspace.library.cofc.edu/iiif/#{identifier}/manifest"

# Actually fetch the contents of the remote URL as a String.
buffer = open(manifest).read

# Convert the JSON response to hash
multi = JSON.parse(buffer)

# Clear out empty metadata fields that RS includes for some reason
multi["metadata"].delete_if { |h| h["value"] == "" }
multi["metadata"].delete_if { |h| h["value"] == [] }

#get values for each filestore alt file url
solr_alt_query = "http://10.7.130.237:8983/solr/rspace/select?fl=alternative-files&q=rspace-id:#{rspaceid}&rows=1"
alt_buffer = open(solr_alt_query).read
alt_document = JSON.parse(alt_buffer)


unless alt_document["response"]["docs"][0]["alternative-files"].nil?

altFiles = alt_document["response"]["docs"][0]["alternative-files"]

base_canvas = multi["sequences"][0]["canvases"][0]

altFiles.each.with_index(1) do |canvas,i|
c = Marshal.load(Marshal.dump(base_canvas))

canvas = canvas[30..-1]
canvas = CGI.escape(canvas)

altInfo = "https://iiif.library.cofc.edu/iiif/2/#{canvas}/info.json"
buffer = open(altInfo).read
alt = JSON.parse(buffer)
height = 85
width = alt["width"]

c["height"] = height
c["width"] = width
c["@id"] = "http://rspace.library.cofc.edu/iiif/#{identifier}/canvas/#{i}"
c["label"] = "#{i}"
c["images"][0]["@id"] = "http://rspace.library.cofc.edu/iiif/#{identifier}/annotation/#{i}"
c["images"][0]["on"] = "http://rspace.library.cofc.edu/iiif/#{identifier}/canvas/#{i}"
c["images"][0]["height"] = height
c["images"][0]["width"] = width
c["images"][0]["resource"]["@id"] = "https://iiif.library.cofc.edu/iiif/2/#{canvas}/full/full/0/default.jpg"
c["images"][0]["resource"]["service"]["@id"] = "https://iiif.library.cofc.edu/iiif/2/#{canvas}"

multi["sequences"][0]["canvases"] << c

end


end

File.open("manifests/multi/#{identifier}.json","w") do |f|
  f.write(JSON.pretty_generate(multi))
end

render json: multi

end #end else
end #end generate multi


#generate otherContent annotationList 
#generic json render with page data
def other_manifest

iiif_identifier = params[:iiif_identifier]

annotation_json = '{"@context":"//iiif.io/api/presentation/2/context.json","@id":"https://manifests.sub.uni-goettingen.de/iiif/presentation/PPN235181684_0174/list/gdz:PPN235181684_0174:00000003","@type":"sc:AnnotationList","resources":[{"@context":"//iiif.io/api/presentation/2/context.json","@type":"oa:Annotation","motivation":"sc:painting","resource":{"@id":"https://gdz.sub.uni-goettingen.de/fulltext/PPN235181684_0174/00000003","@type":"dctypes:Text","format":"text/html"}}]}'
annotation_list = JSON.parse(annotation_json)

annotation_list["@id"] = "https://beta.lcdl.library.cofc.edu/lcdl/collections/annotation?iiif_identifier=#{iiif_identifier}"
annotation_list["resources"][0]["resource"]["@id"] = "https://beta.lcdl.library.cofc.edu/lcdl/collections/fulltext?iiif_identifier=#{iiif_identifier}"

render json: annotation_list

end

#generate html response to transcript
#probably solr query for trans and page md, render html
def iiif_fulltext

iiif_identifier = params[:iiif_identifier]

page_metadata = "http://10.7.130.237:8983/solr/rspace/select?fl=transcript,title,description,pageorder&q=iiif:#{iiif_identifier}&wt=json"
page = open(page_metadata).read
page = JSON.parse(page)

title = page["response"]["docs"][0]["title"]
description = page["response"]["docs"][0]["description"]
transcript = page["response"]["docs"][0]["transcript"]
pageorder = page["response"]["docs"][0]["pageorder"]

render html: "<div class='metadata'><h4>Title:</h4><p>#{title}</p><h4>Transcript:</h4><p>#{transcript}</p>".html_safe

end


end
