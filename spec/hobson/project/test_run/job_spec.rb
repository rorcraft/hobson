require 'spec_helper'

describe Hobson::Project::TestRun::Job do

  subject{ Factory.job }
  alias_method :job, :subject

  either_context do

    describe "#data" do
      it "should be a subset of test_run.data" do
        job.test_run['a'] = 'b'
        job['a'].should be_nil
        job['c'] = 'd'
        job['c'].should == 'd'
      end
    end

    %w{created enqueued checking_out_code preparing running_tests saving_artifacts tearing_down complete}.each do |landmark|
      it { should respond_to "#{landmark}!" }
      it { should respond_to "#{landmark}_at" }
      context "#{landmark} landmark" do
        before{ job['created_at'] = nil }
        it "should return a Time" do
          job.send("#{landmark}_at").should == nil
          job.send("#{landmark}!")
          job.send("#{landmark}_at").should be_a Time
        end
      end
    end

    it "should presist" do
      test_run = Factory.test_run
      job = Hobson::Project::TestRun::Job.new(test_run, 1)
      job.keys.should == ['created_at']
      job[:x] = 42
      job[:y] = 69
      job.keys.should == ['created_at', 'x', 'y']

      test_run = test_run.project.test_runs(test_run.id)
      job = Hobson::Project::TestRun::Job.new(test_run, 1)
      job[:x].should == 42
      job[:y].should == 69
      job.keys.should == ['created_at', 'x', 'y']
    end

    describe "#enqueue!" do
      it "should enqueue 1 Hobson::Project::TestRun::Runner resque job" do
        Resque.should_receive(:enqueue).with(Hobson::Project::TestRun::Runner, job.test_run.project.name, job.test_run.id, job.index).once
        job.enqueue!
      end
    end

  end

  worker_context do

    describe "#tests" do

      # context "before being assigned tests" do
      #   it "should be an empty array" do
      #     job.test.should == []
      #   end
      # end
      # context "after being assigned tests" do
      #   before{
      #     @tests = (0...4).map{|i| Hobson::Project::Tests::Test.new(job.test_run, "features/#{i}.feature") }
      #     job.test_run.tests.mock(:tests).and_return(@tests)
      #   }
      #   it "should be an array a subject of test_run.tests" do
      #     job.test_run.tests.length.should == 4
      #     job.test.should == []
      #   end
      # end
    end

    describe "#save_artifact" do

      it "should store a key in the redis hash and write a file to S3" do
        file = stub(:public_link => 'http://example.com')
        job.should_receive(:save_file).and_return(file)
        job.save_artifact('Gemfile').should == file
        job.artifacts.should == {'Gemfile' => 'http://example.com'}
      end

    end

  end

end
