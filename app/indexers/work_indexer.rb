require 'nokogiri'
require 'open-uri'
require 'linkeddata'
class WorkIndexer < Hyrax::WorkIndexer

  def generate_solr_document
    super.tap do |solr_doc|
      if (image_id = solr_doc['hasRelatedImage_ssim']).present?
        solr_doc['relatedImageId_ss'] = solr_doc['hasRelatedImage_ssim'].map{|fsid|FileSet.find(fsid).original_file.id}.first
      end
      return solr_doc unless solr_doc['has_model_ssim'].include?("Work") or solr_doc['generic_type_sim'].include?("Work") or (solr_doc["human_readable_type_tesim"] == "Work") or (solr_doc["human_readable_type_ssim"] == "Work")
      solr_doc = index_controlled_fields(solr_doc)
      solr_doc = merge_fields(:subject, [:subjectTopic,:subjectName,:subjectTemporal,:subjectPlace], solr_doc, :stored_searchable)
      solr_doc = merge_fields(:subject, [:subjectTopic,:subjectName,:subjectTemporal,:subjectPlace], solr_doc, :facetable)
      solr_doc = merge_fields(:callNumber, [:itemCallNumber,:collectionCallNumber,:boxFolder], solr_doc)
    end
  end

  def schema
    ScoobySnacks::METADATA_SCHEMA
  end

  def merge_fields(merged_field_name, fields_to_merge, solr_doc, solr_descriptor = :stored_searchable)
    merged_field_contents = []
    fields_to_merge.each do |field_name|
      field = schema.get_field(field_name.to_s)
      if (indexed_field_contents = solr_doc[field.solr_name])
        merged_field_contents.concat(indexed_field_contents)
      end
    end
    solr_name = Solrizer.solr_name(merged_field_name, solr_descriptor)
    solr_doc[solr_name] = merged_field_contents unless merged_field_contents.blank?
    return solr_doc
  end

  def index_controlled_fields(solr_doc)
    return solr_doc unless object.persisted?

    schema.controlled_field_names.each do |field_name|
      field = schema.get_field(field_name)

      # Clear old values from the solr document
      solr_doc.delete Solrizer.solr_name(field_name)
      solr_doc.delete Solrizer.solr_name(field_name.to_sym)
      field.solr_names.each do |solr_name| 
        solr_doc.delete(solr_name)
        solr_doc.delete(solr_name.to_sym)
      end

      # Wrap single objects in arrays if necessary (though it shouldn't be)
#      object[field_name] = Array.wrap(object[field_name])

      # Loop through the different values provided for this property
      object[field_name].each do |val|
        label = ""
        case val
        when ActiveTriples::Resource, URI::regexp
          # We need to fetch the string from an external vocabulary
          label = self.class.fetch_remote_label(val)
          # skip indexing this one if we can't retrieve the label
          next unless label
        when String
          # This is just a normal string (from a legacy model, etc)
          # Go ahead and create a new entry in the appropriate local vocab, if there is one
          if (local_vocab = field.vocabularies.find{|vocab| vocab['authority'].to_s.downcase == 'local'}).is_a?(Hash)
            auth_name = local_vocab['subauthority']
            mintLocalAuthUrl(auth_name, val) if auth_name.present?
            label = val
          else
            #If have a random string and no local vocab, just move on for now
            next
          end
        else
          raise ArgumentError, "Can't handle #{val.class} as a metadata term"
        end
        field.solr_names.each do |solr_name| 
          (solr_doc[solr_name] ||= []) << label
        end
      end
    end
    solr_doc
  end

  def mintLocalAuthUrl(auth_name, value) 
    id = value.parameterize
    auth = Qa::LocalAuthority.find_or_create_by(name: auth_name)
    entry = Qa::LocalAuthorityEntry.create(local_authority: auth,
                                           label: value,
                                           uri: id)
    return localIdToUrl(id,auth_name)
  end

  def localIdToUrl(id,auth_name) 
    root_urls = {production: "https://digitalcollections.library.ucsc.edu",
                 staging: "http://digitalcollections-staging.library.ucsc.edu",
                 development: "http://#{Socket.gethostname}",
                 test: "http://#{Socket.gethostname}"}
    return "#{root_urls[Rails.env.to_sym]}/authorities/show/local/#{auth_name}/#{id}"
  end

  def self.destroy_buffer(url)
    LdBuffer.where(url: url).each{|buffer| buffer.destroy }
  end

  def self.fetch_remote_label(url)
    if url.is_a? ActiveTriples::Resource
      resource = url
      url = resource.id 
    end

    # if it's buffered, return the buffer
    if (buffer = LdBuffer.find_by(url: url))
      if (Time.now - buffer.updated_at).seconds > 1.year
        LdBuffer.where(url: url).each{|buffer| buffer.destroy }
      else
        return buffer.label
      end
    end

    begin

      # handle local qa table based vocabs
      if url.to_s.include?("ucsc.edu") or url.to_s.include?("http://localhost")
        label = JSON.parse(Net::HTTP.get_response(URI(url)).body)["label"]
      # handle geonames specially
      elsif url.include? "geonames.org"
        # make sure we fetch the rdf record, not the normal html one
        if (res_url = url) =~ /geonames.org\/[0-9]+.*\z/ && !res_url.include?("/about.rdf")
          res_url = url.gsub(/(geonames.org\/[0-9]+).*\z/,"\\1/about.rdf")
        end
        # Interpret the xml result ourselves
        doc = Nokogiri::XML(open(res_url))
        label = doc.xpath('//gn:name').first.children.first.text
      # fetch from other normal authorities
      else
        # Smoothly handle some common syntax issues
        cleaned_url = url.dup
        cleaned_url.gsub!("info:lc","http://id.loc.gov") if (url[0..6] == "info:lc")
        cleaned_url.gsub!("/page/","/") if url.include?("vocab.getty.edu")
        resource ||= ActiveTriples::Resource.new(cleaned_url)
        labels = resource.fetch(headers: { 'Accept'.freeze => default_accept_header }).rdf_label
        if labels.count == 1
          label = labels.first
        else
          label = labels.find{|label| label.language.to_s =~ /en/ }.to_s
        end
      end
      
      Rails.logger.info "Adding buffer entry - label: #{label}, url:  #{url.to_s}"
      LdBuffer.create(url: url, label: label)

      # Delete oldest records if we have more than 5K in the buffer
      if (cnt = LdBuffer.count - 5000) > 0
        ids = LdBuffer.order('created_at ASC').limit(cnt).pluck(:id)
        LdBuffer.where(id: ids).delete_all
      end
      
      if label == url && url.include?("id.loc.gov")
        #handle weird alternative syntax
        response = JSON.parse(Net::HTTP.get_response(URI(url)).body)
        response.each do |index, node|
          if node["@id"] == url
            label = node["http://www.loc.gov/mads/rdf/v1#authoritativeLabel"].first["@value"]
          end
        end
      end

      raise Exception if label.to_s == url.to_s

      return label.to_s

    rescue Exception => e
      # IOError could result from a 500 error on the remote server
      # SocketError results if there is no server to connect to
      Rails.logger.error "Unable to fetch #{url} from the authorative source.\n#{e.message}"
      return false
    end
  end
  
  def self.default_accept_header
    RDF::Util::File::HttpAdapter.default_accept_header.sub(/, \*\/\*;q=0\.1\Z/, '')
  end
  
end
