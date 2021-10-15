# This controls how our application indexes collection metadata into Solr
# It is similar to work_indexer but simpler
require 'nokogiri'
require 'open-uri'
require 'linkeddata'
class CollectionIndexer < Hyrax::CollectionIndexer
  THUMBNAIL_WIDTH = 300
  include ControlledIndexerBehavior
  include RepresentativeImageDimensionsIndexBehavior
  include AncestorCollectionBehavior
  include SortableFieldIndexerBehavior

  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc = index_controlled_fields(solr_doc)
      solr_doc = index_representative_image_dimensions(solr_doc)

      # index the sortable fields
      solr_doc = index_sortable_fields(solr_doc)
      
      # index the titles a work's ancestor collections
      solr_doc = index_ancestor_titles(solr_doc)

      # index the field that bulkrax uses to keep track of imported/exported records
      solr_doc[Solrizer.solr_name('bulkrax_identifier', :facetable)] = object.bulkrax_identifier
      solr_doc[Solrizer.solr_name('harmful_language_statement')] = object.harmful_language_statement
      solr_doc[Solrizer.solr_name('subject_terms')] = object.subject_terms
    end
  end

  def schema
    ScoobySnacks::METADATA_SCHEMA
  end
  
end
