#!/usr/bin/env ruby

# Validates that the repository is in a releasable state.
#
#   ruby script/release_check.rb
#   ruby script/release_check.rb --notes-out RELEASE_NOTES.md
#   ruby script/release_check.rb --github-output "$GITHUB_OUTPUT"
#
# Exits non-zero with an explanation when any of the following is true:
#
#   * VERSION is missing from lib/paidnow_sdk/version.rb or is not semver
#   * the gemspec fails to load, or its version disagrees with VERSION
#   * CHANGELOG.md has no section for VERSION
#   * the section for VERSION is not the topmost section
#   * the section for VERSION has no content

require 'rubygems'

module ReleaseCheck
  ROOT = File.expand_path('..', __dir__)
  VERSION_FILE = File.join(ROOT, 'lib', 'paidnow_sdk', 'version.rb')
  CHANGELOG_FILE = File.join(ROOT, 'CHANGELOG.md')
  GEMSPEC_FILE = File.join(ROOT, 'paidnow_sdk.gemspec')

  # X.Y.Z, optionally followed by a prerelease suffix such as -rc1 or .beta.2
  SEMVER = /\A\d+\.\d+\.\d+(?:[-.][0-9A-Za-z][0-9A-Za-z.-]*)?\z/.freeze
  HEADING = /^##\s+\[?(\d+\.\d+\.\d+(?:[-.][0-9A-Za-z][0-9A-Za-z.-]*)?)\]?/.freeze

  class Failure < StandardError; end

  Section = Struct.new(:version, :body)

  class << self
    def run(argv)
      version = declared_version
      check_semver(version)
      check_gemspec(version)
      section = check_changelog(version)

      puts "release_check: version #{version} OK, gemspec agrees, CHANGELOG.md section " \
           "[#{version}] has #{section.body.strip.lines.count} lines"
      write_outputs(argv, version, section)
      0
    rescue Failure => e
      warn "release_check: #{e.message}"
      1
    end

    private

    def declared_version
      match = read(VERSION_FILE).match(/VERSION\s*=\s*['"]([^'"]+)['"]/)
      raise Failure, "no VERSION constant found in #{rel(VERSION_FILE)}" unless match

      match[1]
    end

    def check_semver(version)
      return if SEMVER.match?(version)

      raise Failure, "VERSION #{version.inspect} is not a semantic version (expected X.Y.Z)"
    end

    # Compared as Gem::Version rather than as strings: rubygems normalises a
    # prerelease such as 0.2.0-rc1 to 0.2.0.pre.rc1.
    def check_gemspec(version)
      spec = Gem::Specification.load(GEMSPEC_FILE)
      raise Failure, "#{rel(GEMSPEC_FILE)} did not load as a gem specification" unless spec
      return if spec.version == Gem::Version.new(version)

      raise Failure, "gemspec version #{spec.version} does not match VERSION #{version}"
    end

    def check_changelog(version)
      sections = changelog_sections
      raise Failure, "#{rel(CHANGELOG_FILE)} contains no version sections" if sections.empty?

      section = sections.find { |candidate| candidate.version == version }
      raise Failure, missing_section_message(version, sections) unless section
      raise Failure, out_of_order_message(version, sections) unless sections.first == section
      raise Failure, empty_section_message(version) if section.body.strip.empty?

      section
    end

    def missing_section_message(version, sections)
      known = sections.map(&:version).first(5).join(', ')
      "#{rel(CHANGELOG_FILE)} has no '## [#{version}]' section; add one before releasing " \
        "(sections found: #{known})"
    end

    def out_of_order_message(version, sections)
      "the #{version} section of #{rel(CHANGELOG_FILE)} is not the topmost section " \
        "(found #{sections.first.version} first); the release being cut must be listed first"
    end

    def empty_section_message(version)
      "the #{version} section of #{rel(CHANGELOG_FILE)} is empty; describe what changed"
    end

    def changelog_sections
      sections = []
      read(CHANGELOG_FILE).each_line do |line|
        match = HEADING.match(line)
        if match
          sections << Section.new(match[1], +'')
        elsif sections.any?
          sections.last.body << line
        end
      end
      sections
    end

    def write_outputs(argv, version, section)
      notes_path = flag(argv, '--notes-out')
      File.write(notes_path, "#{section.body.strip}\n") if notes_path

      github_output = flag(argv, '--github-output')
      return unless github_output

      File.open(github_output, 'a') do |file|
        file.puts "version=#{version}"
        file.puts "tag=v#{version}"
      end
    end

    def flag(argv, name)
      index = argv.index(name)
      return nil unless index

      argv[index + 1] || raise(Failure, "#{name} requires a path")
    end

    def read(path)
      raise Failure, "#{rel(path)} does not exist" unless File.file?(path)

      File.read(path)
    end

    def rel(path)
      path.sub("#{ROOT}/", '')
    end
  end
end

exit ReleaseCheck.run(ARGV) if $PROGRAM_NAME == __FILE__
