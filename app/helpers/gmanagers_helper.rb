module GmanagersHelper

  def link_to_group(id)
    name = Gmanager.get_group_name_by_id(id)
    return link_to name, gmanager_path(id, :project_id => params[:project_id])
  end

  def render_group_by_id(id)
    return Gmanager.get_group_name_by_id(id)
  end

  def render_cf_keys()
    return Gmanager.get_user_cf_keys()
  end

  def render_cf_values(id)
    return Gmanager.get_user_cf_values(id)
  end

  def render_group_owner(idgr)
    id = Gmanager.get_group_owner(idgr)
    return id
  end

  def render_user_name(id)
    ret =  Gmanager.get_user_name(id)    
    if not ret
      return Gmanager.get_user_name('1')
    else
      return ret
    end
  end

  def render_possible_owners()
    users = User.all
    ret = []
    for u in users
      ret.append([u['firstname'].to_s + " " + u['lastname'].to_s, u['id']])
    end
    return ret
  end

  def principals_check_box_tags_gmanager(name, principals)
    s = ''
    principals.each do |principal|
      s << "<label>#{ check_box_tag name, principal.id, false, :id => nil } #{h principal}</label><br />"
    end
    s.html_safe
  end
  def render_principals_for_new_group_users_gmanager(group)
    scope = User.active.sorted.not_in_group(group).like(params[:q])
    principal_count = scope.count
    principal_pages = Redmine::Pagination::Paginator.new principal_count, 100, params['page']
    principals = scope.offset(principal_pages.offset).limit(principal_pages.per_page).all

    s = content_tag('div', principals_check_box_tags_gmanager('user_select[]', principals), :id => 'principals')

    links = pagination_links_full(principal_pages, principal_count, :per_page_links => false) {|text, parameters, options|
      link_to text, autocomplete_for_user_gmanager_path(group, parameters.merge(:q => params[:q], :format => 'js')), :remote => true
    }

    s + content_tag('p', links, :class => 'pagination') 
  end

end
