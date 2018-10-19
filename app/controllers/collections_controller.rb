class CollectionsController < ApplicationController


require 'open-uri'
require 'json'
require 'pp'


def solr_manifest

identifier = params[:id]

# Construct the URL we'll be calling
request = "http://10.7.130.237:8983/solr/rspace/select?fl=iiif,iiiftype,label&q=collectionidentifier:%22#{identifier}%22&rows=500&wt=json"

# Actually fetch the contents of the remote URL as a String.
buffer = open(request).read

# Convert the String response into a plain old Ruby array. It is faster and saves you time compared to the standard Ruby libraries too.
result = JSON.parse(buffer)

keys_to_extract = ["response"]

response = result.select { |key,_| keys_to_extract.include? key }

response["@context"] = "http://iiif.io/api/presentation/2/context.json"
response["@id"] = "http://iiif.io/api/presentation/2.1/example/fixtures/collection.json"
response["@type"] = "sc:Collection"
response["label"] = "Collection"

response.tap{|d| d["response"].tap{|h| h.delete("numFound")}}
response.tap{|d| d["response"].tap{|h| h.delete("start")}}
response.tap{|d| d["response"].tap{|h| h.delete("maxScore")}}

response = response.merge(response.delete("response"))

response["manifests"] = response.delete("docs")

response["manifests"].each do |key, value|
  key["@id"] = key.delete("iiif")
  key["@type"] = key.delete("iiiftype")
end

render json: response

end


def compound_manifest

identifier = params[:identifier]

if File.file?("/webapps/bl7/manifests/compound/#{identifier}.json")

manifest = File.read("/webapps/bl7/manifests/compound/#{identifier}.json")
render :json => manifest

else

compound_iiif = "http://10.7.130.241/resourcespace/iiif/#{identifier}/manifest"

# Actually fetch the contents of the remote URL as a String.
buffer = open(compound_iiif).read

# Convert the String response into a plain old Ruby array. It is faster and saves you time compared to the standard Ruby libraries too.
compound = JSON.parse(buffer)
compound.delete("sequences")

#Get page list from Solr query 
page_list = "http://10.7.130.237:8983/solr/rspace/select?fl=iiif,pageorder&q=collectionidentifier:%22cd1782%22&rows=5000&wt=json"
page_buffer = open(page_list).read
pages = JSON.parse(page_buffer)
pages = pages["response"]["docs"]

#Order page list by page order and strip down to array for iteration
order = {}
pages.each do |page| order[page["pageorder"]]= page["iiif"] end
order.sort_by { |k,v| v}
list = []
order.each do |o| list.push(o[1]) end

#set array to hold all canvases
sequences = {}
canvases = []

#call each page manifest, isolate sequence, then add canvas to array
list.each do |l|
  list_buffer = open(l).read
  page_iiif = JSON.parse(list_buffer)
  page_sequences = page_iiif["sequences"]
  page_sequences.each do |sequence| 
    canvases.push(sequence["canvases"][0]) 
  end
end

wrap = []

sequences["@id"] = "http://10.7.130.241/resourcespace/iiif/test/sequence/normal"
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

identifier = params[:identifier]

if File.file?("/manifests/multi/#{identifier}.json")

manifest = File.read("/manifests/multi/#{identifier}.json")
render :json => manifest

else

manifest = "http://10.7.130.241/resourcespace/iiif/#{identifier}/manifest"

# Actually fetch the contents of the remote URL as a String.
buffer = open(manifest).read

# Convert the String response into a plain old Ruby array. It is faster and saves you time compared to the standard Ruby libraries too.
multi = JSON.parse(buffer)

#get values for each filestore alt file url
altFiles = ["filestore%2f1%2f8%2f3%2f2%2f4_4f9fcbc685765ac%2f18324_alt_11_9d97c2515895d82.jpg"]


base_canvas = multi["sequences"][0]["canvases"][0]


altFiles.each.with_index(1) do |canvas,i|
c = Marshal.load(Marshal.dump(base_canvas))
altInfo = "http://10.7.130.241:8080/cantaloupe-4.0.1/iiif/2/#{canvas}/info.json"
buffer = open(altInfo).read
alt = JSON.parse(buffer)
height = 85
width = alt["width"]

c["height"] = height
c["width"] = width
c["@id"] = "http://10.7.130.241/resourcespace/iiif/chscd17820293382/canvas/#{i}"
c["label"] = "#{i}"
c["images"][0]["@id"] = "http://10.7.130.241/resourcespace/iiif/chscd17820293382/annotation/#{i}"
c["images"][0]["on"] = "http://10.7.130.241/resourcespace/iiif/chscd17820293382/canvas/#{i}"
c["images"][0]["height"] = height
c["images"][0]["width"] = width
c["images"][0]["resource"]["@id"] = "http://10.7.130.241:8080/cantaloupe-4.0.1/iiif/2/#{canvas}/full/full/0/default.jpg"
c["images"][0]["resource"]["service"]["@id"] = "http://10.7.130.241:8080/cantaloupe-4.0.1/iiif/2/#{canvas}"

multi["sequences"][0]["canvases"] << c

end

File.open("manifests/multi/#{identifier}.json","w") do |f|
  f.write(JSON.pretty_generate(multi))
end

render json: multi

end #end else
end #end generate multi





end
