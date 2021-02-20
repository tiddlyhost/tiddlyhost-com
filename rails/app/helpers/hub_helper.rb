module HubHelper

  def sort_url(new_sort)
    params.permit(:sort, :search).merge(sort: new_sort)
  end

  def clear_search_url
    params.permit(:sort, :search).merge(search: nil)
  end

end
