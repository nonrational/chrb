module Chrb
  class BulkLabelRename
    def initialize(pattern, replacement)
      @pattern = pattern
      @replacement = replacement
    end

    attr_reader :pattern, :replacement

    def save!
      matching_labels.each do |l|
        l.name = l.name.gsub(pattern, replacement)
        l.save if l.changes.any?
      end
    end

    def matching_labels
      @matching_labels ||= Clubhouse::Label.named_like(pattern).reject(&:archived?)
    end
  end

  class LabelColorChange
    def initialize(pattern, color_name)
      @pattern = pattern
      @color_name = color_name
    end

    attr_reader :pattern, :color_name

    def save!
      matching_labels.each { |l| l.color!(color_name) }
    end

    def names
      matching_labels.map(&:name)
    end

    def count
      matching_labels.count
    end

    def matching_labels
      @matching_labels ||= Clubhouse::Label.named_like(pattern).reject(&:archived?)
    end
  end

  class StaleLabelArchive
    def initialize(pattern)
      @pattern = pattern
    end

    attr_reader :pattern

    def save!
      matching_stale_labels.each { |l| l.archive! }
    end

    def names
      matching_stale_labels.map(&:name)
    end

    def count
      matching_stale_labels.count
    end

    def matching_stale_labels
      @matching_stale_labels ||= Clubhouse::Label.named_like(pattern).select do |l|
        !l.archived? && Time.iso8601(l['updated_at']) < 2.months.ago
      end
    end
  end

  class BulkLabelArchive
    def initialize(pattern)
      @pattern = pattern
    end

    attr_reader :pattern

    def save!
      matching_finished_labels.each { |l| l.archive! }
    end

    def matching_finished_labels
      @matching_finished_labels ||= Clubhouse::Label.all.select do |l|
        l.name =~ pattern && !l.archived? && l.finished?
      end
    end
  end
end
