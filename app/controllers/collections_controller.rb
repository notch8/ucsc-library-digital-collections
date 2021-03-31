class CollectionsController < Hyrax::CollectionsController
  layout :resolve_layout
  self.presenter_class = Ucsc::CollectionPresenter
  skip_load_and_authorize_resource :only => :show_all
  load_and_authorize_resource except: [:index, :create], instance_name: :collection

  def resolve_layout
    return "hyrax/1_column" if action_name == "show_all"
    query_collection_members
    return "collection_with_subcollections" if @subcollection_count > 0
    "hyrax"
  end

  def search_action_url options = {}
    url_for(options.reverse_merge(action: 'index', controller: 'catalog').deep_merge(f: {"ancestor_collection_titles_ssim" => Array(@collection.title)}))
  end

  def show_all
	builder = Hyrax::CollectionSearchBuilder.new(self).with(params.except(:q))
    @response = repository.search(builder)
    @collections = @response.documents.select{ |col| ["open","campus"].include?(col.visibility)}
  rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
    []
  end

end
