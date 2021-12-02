require_relative '../../spec_helper.rb'

describe Salus::RepoSearcher do
  describe 'matching_repos' do
    let(:repo_path) { 'spec/fixtures/processor/recursive' }
    let(:config) do
      { "pass_on_raise" => false,
        "scanner_timeout_s" => 0,
        "recursion" => {
          "directories" => [],
          "directories_matching" => [],
          "directory_exclusions" => [],
          "static_files" => []
        } }
    end

    it 'should return project repo if not set to recurse' do
      config = { "pass_on_raise" => false, "scanner_timeout_s" => 0 }
      repos = []
      Salus::RepoSearcher.new(repo_path, config).matching_repos do |repo|
        repos << repo
      end
      expect(repos.size).to eq(1)
      expect(repos.first.path_to_repo).to eq(repo_path)
    end

    it 'should not implicity include project repo when supplied with recursion settings' do
      config = { "recursion" => {
        "directories" => ["foo"],
         "directories_matching" => ["bar"],
         "directory_exclusions" => [],
         "static_files" => []
      } }
      repos = []
      Salus::RepoSearcher.new(repo_path, config).matching_repos do |repo|
        repos << repo
      end
      expect(repos).to be_empty
    end

    it 'should support static directories' do
      config = { "recursion" => {
        "directories" => ["project-two"],
                "directories_matching" => [],
                "directory_exclusions" => [],
                "static_files" => []
      } }
      repos = []
      Salus::RepoSearcher.new(repo_path, config).matching_repos do |repo|
        repos << repo
      end
      expect(repos.size).to eq(1)

      expect(repos.first.path_to_repo).to eq("spec/fixtures/processor/recursive/project-two")
    end

    it 'should support dynamic directories via content and filename' do
      puts "Debugging Circle: content and filename"
      config = { "recursion" => {
        "directories" => [],
                "directories_matching" => [{ "filename" => "Gemfile.lock",
                                            "content" => "activesupport" }],
                "directory_exclusions" => [],
                "static_files" => []
      } }
      repos = []
      Salus::RepoSearcher.new(repo_path, config).matching_repos do |repo|
        repos << repo
      end

      expect(repos.size).to eq(3) # TODO

      dirs = ["spec/fixtures/processor/recursive",
              "spec/fixtures/processor/recursive/project-two",
              "spec/fixtures/processor/recursive/vendor"]

      expect(repos.map(&:path_to_repo).sort).to eq(dirs)
    end

    it 'should support dynamic directories via content only' do
      puts "Debugging Circle: dynamic dirs via content"
      config = { "recursion" => {
        "directories" => [],
                "directories_matching" => [{ "content" => "activesupport" }],
                "directory_exclusions" => [],
                "static_files" => []
      } }
      repos = []
      Salus::RepoSearcher.new(repo_path, config).matching_repos do |repo|
        repos << repo
      end
      expect(repos.size).to eq(3) # TODO

      dirs = ["spec/fixtures/processor/recursive",
              "spec/fixtures/processor/recursive/project-two",
              "spec/fixtures/processor/recursive/vendor"]

      expect(repos.map(&:path_to_repo).sort).to eq(dirs)
    end

    it 'should support dynamic directories via filename only' do
      config = { "recursion" => {
        "directories" => [],
                "directories_matching" => [{ "filename" => "Gemfile.lock" }],
                "directory_exclusions" => [],
                "static_files" => []
      } }
      repos = []
      Salus::RepoSearcher.new(repo_path, config).matching_repos do |repo|
        repos << repo
      end
      expect(repos.size).to eq(3)

      dirs = ["spec/fixtures/processor/recursive",
              "spec/fixtures/processor/recursive/project-two",
              "spec/fixtures/processor/recursive/vendor"]

      expect(repos.map(&:path_to_repo).sort).to eq(dirs)
    end

    it 'should  filter out exclusions' do
      puts "Debugging Circle: filter exclusions"
      config = { "recursion" => {
        "directories" => [],
                "directories_matching" => [{ "filename" => "Gemfile.lock",
                                            "content" => "activesupport" }],
                "directory_exclusions" => ["vendor"],
                "static_files" => []
      } }
      repos = []
      Salus::RepoSearcher.new(repo_path, config).matching_repos do |repo|
        repos << repo
      end
      expect(repos.size).to eq(2) # TODO

      dirs = ["spec/fixtures/processor/recursive",
              "spec/fixtures/processor/recursive/project-two"]

      expect(repos.map(&:path_to_repo).sort).to eq(dirs)
    end

    it 'should support temporal static files' do
      config = { "recursion" => {
        "directories" => ["project-two"],
                "directories_matching" => [],
                "directory_exclusions" => [],
                "static_files" => ["Gemfile"]
      } }

      base = File.expand_path(repo_path)
      dest = File.expand_path("spec/fixtures/processor/recursive/project-two")
      expect_any_instance_of(Salus::FileCopier)
        .to receive(:copy_files).with(base, dest, ["Gemfile"]).and_call_original

      repos = []
      Salus::RepoSearcher.new(repo_path, config).matching_repos do |repo|
        repos << repo
      end
      expect(repos.size).to eq(1)
      expect(repos.first.path_to_repo).to eq("spec/fixtures/processor/recursive/project-two")
    end
  end
end
