require 'rspec'
require 'rack/test'
require './rapier'
require 'ostruct'

describe Rapier do
  include Rack::Test::Methods

  describe 'A simple API' do
    let(:app) do
      Rapier::API.new do |api|
        api.enable_spec = true

        api.object(:widget) do |obj|
          obj.field(:name,
            :type => :string,
            :description => "The name of this widget",
            :required => true)
          obj.field(:id,
            :type => :integer,
            :description => "The ID number of this widget",
            :required => true)
          obj.field(:note,
            :type => :string,
            :description => "A note to go with this widget",
            :required => false)
        end

        api.route('/create_widget') do |route|
          route.parameter(:name,
            :type => :string,
            :description => 'The name for the newly created widget',
            :required => true)
          route.parameter(:note,
            :type => :string,
            :description => 'An optional note for the new widget',
            :required => false)
          route.parameter(:make_public,
            :type => :boolean,
            :description => 'Should this widget be made public?',
            :required => false)

          route.response_object do |r|
            r.object(:widget,
              :object_type => :widget,
              :optional => :false)
          end

          route.respond do |parameters, response|
            widget = OpenStruct.new(
              :name => parameters['name'],
              :id => (rand() * 100).to_i)

            response.widget.set_from_attrs(widget)
          end
        end
      end
    end

    it 'fails when a required param is not given' do
      post('create_widget', {:note => 'flalala'})
      last_response.status.should(eql(400))
    end

    it 'succeeds when the correct params are given' do
      post('create_widget', {
        :name => 'new widget',
        :make_public => true,
        :note => 'flalala'})
      last_response.status.should(eql(200))
    end

    it 'fails when a param of the wrong type is given' do
      post('create_widget', 
        {:name => 'new widget', :make_public => 5 })
      last_response.status.should(eql(400))
    end

    it 'includes all response object fields' do
      post('create_widget',
        {:name => 'new widget', :make_public => true})
      res = JSON.parse(last_response.body)
      res['widget'].should_not(be_nil)
      ['name', 'id'].each {|k| res['widget'][k].should_not(be_nil) }
    end
  end
end
