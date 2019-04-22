require 'scooby_snacks/blacklight_configuration'
require 'ucsc/oai/solr_document_provider'
class CatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior  
  include BlacklightOaiProvider::Controller

#  include BlacklightAdvancedSearch::Controller

  # This filter applies the hydra access controls
  before_action :enforce_show_permissions, only: :show

  def self.uploaded_field
    solr_name('system_create', :stored_sortable, type: :date)
#    solr_name('date_created', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('system_modified', :stored_sortable, type: :date)
#    solr_name('date_modified', :stored_sortable, type: :date)
  end

  configure_blacklight do |config|

    schema = ScoobySnacks::METADATA_SCHEMA

    config.oai = {
      provider: {
        repository_name: 'UC Santa Cruz Library Digital Collections',
        repository_url: 'http://digitalcollections.library.ucsc.edu/catalog/oai',
        record_prefix: 'oai:ucsc',
        admin_email: 'ethenry@ucsc.edu',
        sample_id: 'q811kj606'
      },
      document: {
        limit: 25,            # number of records returned with each request, default: 15
        set_fields: [
#          {label: "Work Type", solr_field: "has_model_ssim"},
          {label: "Collection", solr_field: "member_of_collections_ssim"}
        ]        # ability to define ListSets, optional, default: nil
      }
    }

    config.view.gallery.partials = [:index_header, :index]
    config.view.gallery.default = true
#    config.gallery.title_only_by_default = true

    config.view.list.default = false
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]


    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)


    config.search_builder_class = CatalogSearchBuilder

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10,
      qf: schema.default_text_search_solrized_field_names
    }

    # solr field configuration for document/show views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_field = 'thumbnail_path_ss'


    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    ScoobySnacks::BlacklightConfiguration.add_facet_fields(config)

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display

    ScoobySnacks::BlacklightConfiguration.add_index_fields(config)
    config.add_index_field solr_name("subject"), label: "Subject"

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display

    ScoobySnacks::BlacklightConfiguration.add_show_fields(config)
    config.add_show_field solr_name("subject"), label: "Subject"

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
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    ScoobySnacks::BlacklightConfiguration.add_search_fields(config)

    config.add_search_field('all_fields', label: 'All Fields', include_in_advanced_search: false) do |field|
      all_names = config.show_fields.values.map(&:field).join(" ")
      title_name = solr_name("title", :stored_searchable)
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim all_text_timv",
        pf: title_name.to_s
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value

    ScoobySnacks::BlacklightConfiguration.add_sort_fields(config)

    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
    config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # disable the bookmark control from displaying in gallery view
  # Hyrax doesn't show any of the default controls on the list view, so
  # this method is not called in that context.
  def render_bookmarks_control?
    false
  end

  def oai_provider
    @oai_provider ||= Ucsc::Oai::SolrDocumentProvider.new(self,oai_config)
  end

end
