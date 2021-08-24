class Snapshot
  attr_reader :snapshot_id

  def initialize(snapshot_id)
    @snapshot_id = snapshot_id
  end

  def check_value
    @snapshot_id.nil? || @snapshot_id == 0
  end
end
