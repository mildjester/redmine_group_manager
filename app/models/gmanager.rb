class Gmanager < ActiveRecord::Base
  unloadable
  
  #show all project groups
  #returns hash {id_group => [array of users in group]}
  def self.getAll(pr_id)
    pr_id = pr_id.to_s
    pid = Project.find_by_identifier(pr_id).id
    mem = Member.where(:project_id => pid).order("user_id ASC")
    res = { }
    for m in mem
      begin
        gr = Group.find(m.user_id)
        users = User.in_group(m.user_id)
        res[m.user_id] = users
        rescue
        #if not group go next by loop
           next
      end
    end
    return res
  end

  #return group owner's id (user id) if exists
  #idgr - ID of searchable group
  def self.get_group_owner(idgr)
    res = Gmanager.find_by_id_group(idgr)
    res = (res.blank?) ? false : res['id_owner']
    res  
  end
  
  #return user custom field names or an empty array if none are available
  def self.get_user_cf_keys()
    keys = CustomField.where(:type => 'UserCustomField').order(:id)
    res = []
    if !keys.blank?
      i = 0
      keys.each do |c|
        res[i] = c['name']
        i += 1
      end	
    end
    res
  end
  
  #return user custom field values or an empty array if none are available
  def self.get_user_cf_values(id)
    keys = CustomField.where(:type => 'UserCustomField').order(:id)
    values = User.find(id).custom_values.order(:custom_field_id)

    res = []
    if !keys.blank?
      i = 0
      keys.each do |c|
        res[i] = values[i] ? values[i][:value].to_s : "-"
        i += 1
      end	
    end
    res
    #res = { }
    #res[:pos] = val[0] ? val[0][:value].to_s : "-"
    #res[:dep] = val[1] ? val[1][:value].to_s : "-"
    #res
  end

  def self.get_group_name_by_id(id)
    Group.find(id).lastname
  end

  def self.get_group_users(id)
    id = id.to_s
    User.in_group(id)
  end

  #get all users exept group's
  def self.get_all_project_users(id,grid)
    id = id.to_s
    pid = Project.find_by_identifier(id).id
    tres = []
    mem = Member.where(:project_id => pid).to_a
    mem.delete_if{|x| x.user_id==grid}
    mcount = mem.count
    for i in 0..mcount-1
      begin
        user = User.find(mem[i]['user_id'])
        tres.push(user)
      rescue
        tres.concat(User.in_group(mem[i]['user_id']))
        tres.uniq!
      end
    end
  #Fucking dump piecae of code cose index not working    
    gusers = User.in_group(grid)
    temp = []
    gusers.each do |i|
      temp.push(i["id"])
    end
    res = { }
    tres.each do |t|
      if !temp.index(t["id"])
        res[t["id"]] = t["lastname"].to_s + " " + t["firstname"].to_s
      end
    end
    res
  end

  def self.update_name(idgr,name)
    begin
      gr = Group.find(idgr)
      res = gr.update_attributes(:lastname => name.to_s)
      return res
    rescue
      return 0
    end
  end

  def self.delete_user_from_group(idus,idgr)
    gr=Group.find(idgr)
    us=User.find(idus)
    gr.users.delete(us)
    gr.save
  end

  #MAKE check what are you send to db
  #idpr - identifier of project (letter)
  #name - name of group
  #owner - id of user, who create group
  def self.create_group(idpr,name,owner)
    #check the unique of name
    if Group.find_by_lastname(name).blank?    
      gr = Group.create(:lastname => name)
      pid = Project.find_by_identifier(idpr).id
      mem = Member.new(:project_id => pid, :user_id => gr.id) 
      mem.role_ids = [6]
      mem.save 
      Project.find(pid).members << mem
      #create entry in gmanagers table
      gm = Gmanager.create(:id_group => gr.id, :id_owner => owner)
      gm.save
      return true
    else
      return false
    end
end

  #idpr - identifier of project
  #idgr - ID of deleted group
  #iduser - Id of user who wants to delete group
  def self.delete_group(idpr,idgr)
    pgm = Gmanager.find_by_id_group(idgr)
    pid = Project.find_by_identifier(idpr.to_s).id
    idm = Member.find_by_project_id_and_user_id(pid, idgr)
    Member.delete(idm)
    Group.delete(idgr)
    if not pgm.blank?
      Gmanager.delete(pgm)
    end
  end

  #check if user have enough rights to do action to group
  #return bool
  #id_project-identifier of project (not ID)..
  #id_user- ID user
  #action -  desired action (symbol!)
  def self.may_user_do(id_project,id_user,action)
    project = Project.find_by_identifier(id_project)
    user = User.find(id_user)
    roles = user.roles_for_project(project)
    for r in roles
      if r[:permissions].include?(action)
        return true
      end
    end
    return false
  end

  #check if user is owner of the group
  #iduser, idgr - IDs, string
  def self.is_owner(idgr, iduser)
    if Gmanager.find_by_id_group_and_id_owner(idgr, iduser).blank?
      return false
    else
      return true
    end
  end

  #search in Gmanager, if there is no entry - group is admin group
  def self.is_admin_group(idgr)
    if Gmanager.find_by_id_group(idgr).blank?
      return true
    else
      return false
    end
  end

  def self.get_user_name(iduser)
    if iduser
      res = User.find(iduser)
      ret = res['lastname'].to_s + " " + res['firstname'].to_s
      return ret
    else
      return false
    end
  end


  #insert into Gmanager table new entry or change existing
  def self.change_owner(id_group, id_owner)
    gm = Gmanager.find_by_id_group(id_group)
    if gm.blank?
      gm=Gmanager.create(:id_group => id_group, :id_owner => id_owner)
    else
      gm.update_attribute(:id_owner, id_owner)
    end
    gm.save
  end

end
