require 'rstruct'
require 'set'

require_relative 'RLBot'

class RLPlatformRoles
  ##### PRIVATE STRUCTS #####
  Role = RStruct.new(:name)
  private_constant :Role
  ###########################

  ##### PRIVATE CONSTANTS #####
  ROLE_COLOR = 0xff69b4
  private_constant :ROLE_COLOR

  PLATFORM_ROLES = Set['steam', 'xbox', 'ps', 'epic',].freeze
  public_constant :PLATFORM_ROLES
  #############################

  ##### ROLE MANAGEMENT #####
  def self.roles(member, platform)
    platform = platform.to_s
    all_platform_roles = all_roles(member.server)
    return [all_platform_roles.fetch(platform)], all_platform_roles.values
  end

  def self.all_roles(server)
    roles = server.roles.select { |role|
      PLATFORM_ROLES.include?(role.name.downcase)
    }
    all_roles = roles.to_h { |role| [role.name.downcase, role] }
    create_missing_roles(server, all_roles)
    return all_roles
  end
  ###########################

  ##### PRIVATE #####

  def self.create_missing_roles(server, all_roles)
    return if all_roles.size >= PLATFORM_ROLES.size

    PLATFORM_ROLES.each { |role|
      next if all_roles.key?(role)

      all_roles[role] = server.create_role(name: role,
                                           colour: ROLE_COLOR,
                                           hoist: true,
                                           mentionable: true,
                                           permissions: 0)
    }
  end
  private_class_method :create_missing_roles
end
