require 'rstruct'
require 'set'

require_relative 'RLDB'

class RLRegions
  ##### PRIVATE STRUCTS #####
  Role = RStruct.new(:name)
  private_constant :Role
  ###########################

  ##### PRIVATE CONSTANTS #####
  ROLE_COLOR = 0xc0c0c0
  private_constant :ROLE_COLOR

  REGION_ROLES = Set[
    'JPN',
    'ASC',
    'ASM',
    'ME',
    'OCE',
    'SAF',
    'EU',
    'USE',
    'USW',
    'OCE',
  ].freeze
  public_constant :REGION_ROLES
  #############################

  ##### NICK MANAGEMENT #####
  def self.update_nick(member, region)
    return unless region && RLDB.server_region_roles(member.server.id)

    member.nick = "[#{region}] #{member.display_name}"
  rescue Discordrb::Errors::NoPermission, RestClient::BadRequest
    Discordrb::LOGGER.warn("Can't set nick on #{member.server.name}")
  end

  def self.remove_nick(member)
    member.nick = member.display_name.gsub(/^\[[A-Z]+?\]\s+/, '')
  rescue Discordrb::Errors::NoPermission
    Discordrb::LOGGER.warn("Can't remove nick on #{member.server.name}")
  end
  ###########################

  ##### ROLE MANAGEMENT #####
  def self.roles(member, region)
    return [], [] unless region

    all_region_roles = all_roles(member.server)
    return [all_region_roles.fetch(region)], all_region_roles.values
  end

  def self.all_roles(server)
    roles = server.roles.select { |role| REGION_ROLES.include?(role.name) }
    all_roles = roles.to_h { |role| [role.name, role] }
    create_missing_roles(server, all_roles)
    return all_roles
  end
  ###########################

  ##### PRIVATE #####

  def self.create_missing_roles(server, all_roles)
    return if all_roles.size >= REGION_ROLES.size

    REGION_ROLES.each { |role|
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
