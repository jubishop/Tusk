require 'rstruct'

require_relative 'RLRankRoles'
require_relative 'RLRegions'

module RLRoles
  def self.update_roles(member, ranks, region = nil)
    rank_role, all_rank_roles = RLRankRoles.roles(member, ranks)
    region_role, all_region_roles = RLRegions.roles(member, region)

    member.modify_roles(
        rank_role + region_role, # add
        all_rank_roles + all_region_roles) # remove
  rescue Discordrb::Errors::NoPermission
    Discordrb::LOGGER.warn("Can't update roles on #{member.server.name}")
  end

  def self.remove_roles(member)
    all_rank_roles = RLRankRoles.all_roles(member.server).values
    all_region_roles = RLRegions.all_roles(member.server).values

    member.modify_roles(
        [], # add
        all_rank_roles + all_region_roles) # remove
  rescue Discordrb::Errors::NoPermission
    Discordrb::LOGGER.warn("Can't remove roles on #{member.server.name}")
  end
end
