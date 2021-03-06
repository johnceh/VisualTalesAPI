require 'rails_helper'

describe Api::StoriesController do
  describe 'GET #index' do
    context 'with no params' do
      before do
        10.times do |i|
          FactoryGirl.create(:story, title: "movie #{i}")
        end
        get :index
      end
      it 'returns all stories' do
        expect(response.status).to eq 200
        expect(JSON.parse(response.body).size).to eq 10
      end
    end

    context 'with pagination params' do
      before do
        20.times do |i|
          FactoryGirl.create(:story, title: "movie #{i}")
        end
        get :index, page_size: 10, page: 1
      end
      it 'returns page size' do
        expect(response.status).to eq 200
        expect(JSON.parse(response.body).size).to eq 10
        expect(JSON.parse(response.body).last['title']).to eq 'movie 9'
      end
    end

    context 'with search parameters' do
      let(:story_1) { FactoryGirl.create(:story, title: 'the godfather') }
      let(:story_2) { FactoryGirl.create(:story, title: 'star trek') }
      let(:story_3) { FactoryGirl.create(:story, title: 'star wars') }
      let(:story_4) { FactoryGirl.create(:story, title: 'casa blanca') }
      let(:tag_1) { FactoryGirl.create(:tag, name: 'horror') }
      let(:tag_2) { FactoryGirl.create(:tag, name: 'fiction') }
      let(:tag_3) { FactoryGirl.create(:tag, name: 'drama') }
      let(:tag_4) { FactoryGirl.create(:tag, name: 'thriller') }
      let(:story_tag_1) { FactoryGirl.create(:story_tag, story_id: story_1.id, tag_id: tag_3.id) }
      let(:story_tag_2) { FactoryGirl.create(:story_tag, story_id: story_1.id, tag_id: tag_4.id) }
      let(:story_tag_3) { FactoryGirl.create(:story_tag, story_id: story_2.id, tag_id: tag_2.id) }
      let(:story_tag_4) { FactoryGirl.create(:story_tag, story_id: story_3.id, tag_id: tag_2.id) }
      let(:story_tag_5) { FactoryGirl.create(:story_tag, story_id: story_3.id, tag_id: tag_3.id) }
      let(:story_tag_6) { FactoryGirl.create(:story_tag, story_id: story_4.id, tag_id: tag_3.id) }

      context 'by name' do
        before do
          story_tag_1;story_tag_2;story_tag_3;
          story_tag_4;story_tag_5;story_tag_6
          # Example:
          # GET /stories/?title=star
          get :index, title: 'star'
        end
        it 'provides matches' do
          expect(response.status).to eq 200
           expect(JSON.parse(response.body).first.keys).to eq ["id", "title", "author", "email", "description", "created_at", "updated_at"]
          expect(JSON.parse(response.body).size).to eq 2
          expect(JSON.parse(response.body).map{|t| t['title']}).to eq ['star trek','star wars'] 
        end
      end

      context 'by tag_id' do
        before do
          story_tag_1;story_tag_2;story_tag_3;
          story_tag_4;story_tag_5;story_tag_6
          # Example:
          # GET /stories/?tag_ids='1,2,3,4,5'
          get :index, tag_ids: [tag_2.id].join(',')
        end
        it 'provides matches' do
          expect(response.status).to eq 200
          expect(JSON.parse(response.body).first.keys).to eq ["id", "title", "author", "email", "description", "created_at", "updated_at"]
          expect(JSON.parse(response.body).size).to eq 2
          expect(JSON.parse(response.body).map{|t| t['title']}).to eq ['star trek','star wars'] 
        end
      end

    end
  end

  describe 'GET #show' do
    let(:story) { FactoryGirl.create(:story) }
    context 'successful' do
      it 'returns the story' do
        get :show, id: story.id
        expect(response.status).to eq 200
        expect(JSON.parse(response.body).keys).to eq ["id", "title", "author", "email", "description", "created_at", "updated_at"]
      end
    end
    context 'not found' do
      it 'returns 404' do
        get :show, id: 342342
        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST #create' do
    let(:seed) { SecureRandom.uuid }
    before do
      # Example:
      # POST /stories 
      # BODY {"title":"Story X ff0e3a61-3e53-437c-af00-d18674f68679","author":"Author X","email":"story@a.com","description":"Story description"} 
      post :create, {title: "Story X #{seed}", author: 'Author X', email: 'story@a.com', description: 'Story description'}
    end
    context 'successful' do
      it 'creates story' do
        # Response example
        # {"id":3,"title":"Story X 34674540-f608-4f0f-a2e6-7eec9d25b334","author":"Author X","email":"story@a.com","description":"Story description","created_at":"2016-02-20T19:11:43.072Z","updated_at":"2016-02-20T19:11:43.072Z\}
        expect(response.status).to eq 201
        expect(JSON.parse(response.body).keys).to eq ["id", "title", "author", "email", "description", "created_at", "updated_at"]
        story = Story.where(title: "Story X #{seed}")
        expect(story).to be_present
      end
    end
  end

  describe 'PUT #update' do

    let(:story_1) { FactoryGirl.create(:story) }
    let(:updated_attributes) { {title: "title changed", author: 'author changed', email: 'changed@a.com', description: 'description changed'} }
    before do
      # Example:
      # put /stories/:id 
      # BODY {id: "1","title":"Story X ff0e3a61-3e53-437c-af00-d18674f68679","author":"Author X","email":"story@a.com","description":"Story description"} 
      put :update, updated_attributes.merge(id: story_1.id)
    end
    context 'successful' do
      it 'updates story' do
        # Response example
        # {"id":3,"title":"Story X 34674540-f608-4f0f-a2e6-7eec9d25b334","author":"Author X","email":"story@a.com","description":"Story description","created_at":"2016-02-20T19:11:43.072Z","updated_at":"2016-02-20T19:11:43.072Z\}
        expect(response.status).to eq 200
        story = JSON.parse(response.body)
        story = updated_attributes
        story_1.reload
        expect(story_1.title).to eq updated_attributes[:title]
        expect(story_1.email).to eq updated_attributes[:email]
        expect(story_1.author).to eq updated_attributes[:author]
        expect(story_1.description).to eq updated_attributes[:description]
      end
    end
  end







end