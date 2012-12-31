$LOAD_PATH << './'
require 'api'

api = Rapier::API.new do |api|
  api.enable_spec = true

  api.object(:user) do |obj|
    obj.field :login,
      :type => :string,
      :description => "The login name of this user",
      :required => true

    obj.field :id,
      :type => :integer,
      :description => "The id number of this user",
      :required => true

    obj.field :password,
      :type => :string,
      :description => "The user's password",
      :required => false
  end

  api.route('/create_user') do |route|
    route.parameter(:login,
      :type => :string,
      :required => :true,
      :description => 'The user\'s login'
    )

    route.parameter(:password,
      :type => :string,
      :required => true,
      :description => 'The user\'s password')

    route.response_object do |r|
      r.object :user,
        :object_type => :user,
        :exclude_fields => [:friends],
        :optional => true
      r.field :success,
        :type => :boolean
    end

    route.respond do |parameters, response|
      @obj = OpenStruct.new(
        :login => 'newuser1',
        :password => 'flalala')

      response.user.set_from_attrs(@obj)
    #  response.user.set_from_hash(
    #    :login => 'newuser1',
    #    :password => 'flalala')
      response.success = true
      response.user.id = 10
    end
  end
end

run api
