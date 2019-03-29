class BashHistory < ActiveRecord::Base
  belongs_to :instance
  belongs_to :player
  validates :command, presence: true
  validates :performed_at, presence: true
end
