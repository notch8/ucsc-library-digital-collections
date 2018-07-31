require 'socket'
# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument

  include Blacklight::Gallery::OpenseadragonSolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior

  # Adds ScoobySnacks metadata attribute definitions
  include ScoobySnacks::SolrBehavior

  # add collection membership in OAI-PMH feed
  add_field_semantics('isPartOf','member_of_collections_ssim')

  add_field_semantics('identifier','thumbnail_path')

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
  use_extension(Ucsc::Blacklight::Dpla)

  # Do content negotiation for AF models. 

  use_extension( Hydra::ContentNegotiation )

  def permalink(record = self)
    "#{root_url}/records/#{record.id}"
  end

  def display_image_path(record = self, size = "large")
    record.thumbnail_path.gsub("thumbnail",size)
  end

  def display_image_url(record = self)
    root_url + display_image_path(record)
  end

  def root_url
    "https://"+Socket.gethostname
  end

  def member_ids
    fetch('member_ids_ssim', [])
  end

  def file_set_ids    
    fetch('file_set_ids_ssim', [])
  end

  def date_digitized
    self[Solrizer.solr_name('date_digitized')]
  end

  def physical_format
    self[Solrizer.solr_name('physical_format')]
  end

  def digital_extent
    self[Solrizer.solr_name('digital_extent')]
  end

  def digital_publisher_homepage
    self[Solrizer.solr_name('digital_publisher_homepage')]
  end

  def parent_course
    return nil if human_readable_type != "Lecture"
    return @parent_course_solr_document unless @parent_course_solr_document.nil?
    query = ActiveFedora::SolrQueryBuilder.construct_query_for_rel("member_ids" => id, "has_model" => "Course")
    response = ActiveFedora::SolrService.instance.conn.get(ActiveFedora::SolrService.select_path, params: { fq: query, rows: 1})["response"]["docs"][0]
    return nil if response.nil?
    @parent_course_solr_document = SolrDocument.new(response)
  end

  def parent_work
    return @parent_work_solr_document unless @parent_work_solr_document.nil?
    query = ActiveFedora::SolrQueryBuilder.construct_query_for_rel("member_ids" => id, "has_model" => "Work")
    response = ActiveFedora::SolrService.instance.conn.get(ActiveFedora::SolrService.select_path, params: { fq: query, rows: 1})["response"]["docs"][0]
    return nil if response.nil?
    @parent_work_solr_document = SolrDocument.new(response)
  end



end
