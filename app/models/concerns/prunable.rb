# "Keep only the newest N" retention for history-like records.
module Prunable
  private

  # Removes every record of `relation` beyond its first `keep`, in the
  # relation's own order, so pass it newest first. Records are deleted with a
  # single statement; pass `destroy: true` when they have callbacks or
  # attachments to clean up.
  def prune_to_newest(relation, keep:, destroy: false)
    excess = relation.unscope(:order).where.not(id: relation.limit(keep).select(:id))
    destroy ? excess.destroy_all : excess.delete_all
  end
end
