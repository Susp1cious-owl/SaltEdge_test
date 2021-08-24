class Snapshot
  attr_reader :snapshot_id

  def initialize(snapshot_id)
    @snapshot_id = snapshot_id
  end

  def check_value
    @snapshot_id.nil? || @snapshot_id == 0
  end
end

class CheckInfoPlaylist
  attr_reader :list

  def initialize
    @list = []
  end

  def add(body)
    @list.append(body)
  end

  def empty
    @list.empty?
  end
end