require 'rstruct'

require_relative 'RLDB'
require_relative 'RLPlatformRoles'
require_relative 'RLRankRoles'
require_relative 'RLRegions'

module RLRoles
  def self.update_roles(member, ranks, platform = nil, region = nil)
    add_roles, remove_roles = RLRankRoles.roles(member, ranks)
    if platform && RLDB.server_platform_roles(member.server.id)
      platform_role, all_platform_roles = RLPlatformRoles.roles(member,
                                                                platform)
      add_roles += platform_role
      remove_roles += all_platform_roles
    end
    if region && RLDB.server_region_roles(member.server.id)
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
    all_platform_roles = RLPlatformRoles.all_roles(member.server).values

    member.modify_roles(
        [], # add
        all_rank_roles + all_region_roles + all_platform_roles) # remove
  rescue Discordrb::Errors::NoPermission
    Discordrb::LOGGER.warn("Can't remove roles on #{member.server.name}")
  end
end
