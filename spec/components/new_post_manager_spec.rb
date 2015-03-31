require 'spec_helper'
require 'new_post_manager'

describe NewPostManager do

  let(:topic) { Fabricate(:topic) }

  context "default action" do
    it "creates the post by default" do
      manager = NewPostManager.new(topic.user, raw: 'this is a new post', topic_id: topic.id)
      result = manager.perform

      expect(result.action).to eq(:create_post)
      expect(result).to be_success
      expect(result.post).to be_present
      expect(result.post).to be_a(Post)
    end
  end

  context "extensibility" do

    let(:counter_handler) do
      lambda do |manager|
        result = nil
        if manager.args[:raw] == 'this post increases counter'
          @counter += 1
          result = NewPostManager::Result.new(:counter, true)
        end

        result
      end
    end

    let(:queue_handler) do
      lambda do |manager|
        manager.args[:raw] =~ /queue me/ ? manager.enqueue('test') : nil
      end
    end

    before do
      @counter = 0
      NewPostManager.add_handler(&counter_handler)
      NewPostManager.add_handler(&queue_handler)
    end

    after do
      NewPostManager.handlers.delete(counter_handler)
      NewPostManager.handlers.delete(queue_handler)
    end

    it "calls custom handlers" do
      manager = NewPostManager.new(topic.user, raw: 'this post increases counter', topic_id: topic.id)

      result = manager.perform

      expect(result.action).to eq(:counter)
      expect(result).to be_success
      expect(result.post).to be_blank
      expect(@counter).to be(1)
      expect(QueuedPost.count).to be(0)
    end

    it "calls custom enqueuing handlers" do
      manager = NewPostManager.new(topic.user, raw: 'to the handler I say enqueue me!', topic_id: topic.id)

      result = manager.perform

      expect(result.action).to eq(:enqueued)
      expect(result).to be_success
      expect(result.post).to be_blank
      expect(QueuedPost.count).to be(1)
      expect(@counter).to be(0)
    end

    it "if nothing returns a result it creates a post" do
      manager = NewPostManager.new(topic.user, raw: 'this is a new post', topic_id: topic.id)

      result = manager.perform

      expect(result.action).to eq(:create_post)
      expect(result).to be_success
      expect(result.post).to be_present
      expect(@counter).to be(0)
    end

  end

end
