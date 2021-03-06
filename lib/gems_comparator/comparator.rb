# frozen_string_literal: true

module GemsComparator
  class Comparator
    def self.convert(gems)
      if defined?(Parallel)
        Parallel.map(gems, &:to_h)
      else
        gems.map(&:to_h)
      end
    end

    def initialize(before_lockfile, after_lockfile)
      @before_lockfile = before_lockfile
      @after_lockfile = after_lockfile
    end

    def compare
      gems = addition_gems + change_gems
      Comparator.convert(gems.sort_by(&:name))
    end

    private

    def parse_lockfile(lockfile)
      parser = Bundler::LockfileParser.new(lockfile)
      parser.specs.map { |spec| [spec.name, spec.version] }.to_h
    end

    def before_gems
      @before_gems ||= parse_lockfile(@before_lockfile)
    end

    def after_gems
      @after_gems ||= parse_lockfile(@after_lockfile)
    end

    def addition_gems
      names = after_gems.keys - before_gems.keys
      names.map { |name| new_geminfo(name) }
    end

    def change_gems
      names = before_gems.keys.reject do |name|
        before_gems[name] == after_gems[name]
      end
      names.map { |name| new_geminfo(name) }
    end

    def new_geminfo(name)
      GemInfo.new(name, before_gems[name].to_s, after_gems[name].to_s)
    end
  end
end
