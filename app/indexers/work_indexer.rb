require 'nokogiri'
require 'open-uri'
require 'linkeddata'
class WorkIndexer < Hyrax::WorkIndexer
  THUMBNAIL_WIDTH = 300
  include ControlledIndexerBehavior

  def ancestor_ids(doc)
    return [] if doc.nil? 
    ids = [doc.id]
    ids += doc.member_of_collection_ids
    ids += ancestor_ids(doc.parent_work)
    return ids.uniq
  end
  
  def generate_solr_document
    super.tap do |solr_doc|
      case solr_doc['has_model_ssim'].first
      when "FileSet"
        solr_doc["file_id_ss"] = object.original_file_id
        solr_doc["ancestor_ids_ssim"] = ancestor_ids(solr_doc)
        visibilities = solr_doc["ancestor_ids_ssim"].map{|id| SolrDocument.find(id).visibility}
        if (special_vis = (['request','campus'] & visibilities)).present?
          solr_doc["visibility_ssi"] = special_vis.first
        else
          solr_doc["visibility_ssi"] = "open" if solr_doc.parent_work.visibility == 'open'
        end
      when "Work"
        solr_doc['file_set_ids_ssim'] = object.file_set_ids
        solr_doc['member_ids_ssim'] = object.ordered_member_ids
        object.ordered_member_ids.each do |member_id|
          next unless (member = SolrDocument.find(member_id)).image?
          solr_doc["hasRelatedImage_ssim"] ||= []
          case member['has_model_ssim'].first
          when "FileSet"
            solr_doc["hasRelatedImage_ssim"] << member_id
            (solr_doc["file_set_ids_ssim"] ||= []) << member_id 
          when "Work"
            solr_doc["hasRelatedImage_ssim"]  += member["hasRelatedImage_ssim"]
          end
        end
        solr_doc["hasRelatedImage_ssim"] = (solr_doc["hasRelatedImage_ssim"] || []).uniq
        solr_doc["file_set_ids_ssim"] = (solr_doc["file_set_ids_ssim"] || []).uniq

        solr_doc = index_controlled_fields(solr_doc)
        solr_doc = inherit_fields(solr_doc)

        # I think that merging fields is now supported by blacklight on the display end. Look in to that?
        solr_doc = merge_fields(:subject, [:subjectTopic,:subjectName,:subjectTemporal,:subjectPlace], solr_doc, :stored_searchable)
        solr_doc = merge_fields(:subject, [:subjectTopic,:subjectName,:subjectTemporal,:subjectPlace], solr_doc, :facetable)
        solr_doc = merge_fields(:callNumber, [:itemCallNumber,:collectionCallNumber,:boxFolder], solr_doc)
        
        # If this work has a related images but the thumbnail has not been set correctly, set the thumbnail
        if (image_ids = solr_doc['hasRelatedImage_ssim']).present?
          if solr_doc['thumbnail_path_ss'].blank? or solr_doc['thumbnail_path_ss'].to_s.downcase.include?("work")
            solr_doc['thumbnail_path_ss'] = "/downloads/#{image_ids.last}?file=thumbnail"
          end
        end
      when "Collection"
        solr_doc = index_controlled_fields(solr_doc)

      end
    end
  end

  def schema
    ScoobySnacks::METADATA_SCHEMA
  end

  def inherit_fields solr_doc
    return solr_doc unless Array(object.metadataInheritance).first.to_s.downcase.include?("index")
    return solr_doc unless object.member_of.present?
    object.member_of.each do |parent_work|
      parent_doc = SolrDocument.find(parent_work.id)
      ScoobySnacks::METADATA_SCHEMA.inheritable_fields.each do |field| 
        next if solr_doc[field.solr_name].present?
        solr_doc[field.solr_name] = parent_doc[field.solr_name]
      end
    end
    return solr_doc
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
end
