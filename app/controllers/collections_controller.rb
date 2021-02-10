class CollectionsController < Hyrax::CollectionsController
  layout :resolve_layout
  self.presenter_class = Ucsc::CollectionPresenter
  skip_load_and_authorize_resource :only => :show_all

  def resolve_layout
    return "hyrax" if action_name == "show_all"
    query_collection_members
    return "collection_with_subcollections" if @subcollection_count > 0
    "hyrax"
  end

  def search_action_url options = {}
    url_for(options.reverse_merge(action: 'index', controller: 'catalog').deep_merge(f: {"ancestor_collection_titles_ssim" => Array(@collection.title)}))
  end

  def show_all
  end
  
end
