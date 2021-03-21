require 'rstruct'

require_relative 'RLRankRoles'
require_relative 'RLRegions'

module RLRoles
  def self.update_roles(member, ranks, region = nil)
    add_roles, remove_roles = RLRankRoles.roles(member, ranks)
    if region
      region_role, all_region_roles = RLRegions.roles(member, region)
      add_roles += region_role
      remove_roles += all_region_roles
    end

    member.modify_roles(add_roles, remove_roles)
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
