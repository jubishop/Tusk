require 'rstruct'

require_relative 'RLDB'
require_relative 'RLRanks'

class RLRankRoles
  ##### PRIVATE STRUCTS #####
  Role = RStruct.new(:name, :position, :color)
  private_constant :Role
  ###########################

  ##### PRIVATE CONSTANTS #####
  ROLE_BY_RANK = [
    Role.new('Bronze I', 0, 0xc27c0e),
    Role.new('Bronze II', 1, 0xc27c0e),
    Role.new('Bronze III', 2, 0xc27c0e),
    Role.new('Silver I', 3, 0x95a5a6),
    Role.new('Silver II', 4, 0x95a5a6),
    Role.new('Silver III', 5, 0x95a5a6),
    Role.new('Gold I', 6, 0xf1c40f),
    Role.new('Gold II', 7, 0xf1c40f),
    Role.new('Gold III', 8, 0xf1c40f),
    Role.new('Platinum I', 9, 0x607d8b),
    Role.new('Platinum II', 10, 0x607d8b),
    Role.new('Platinum III', 11, 0x607d8b),
    Role.new('Diamond I', 12, 0x3498db),
    Role.new('Diamond II', 13, 0x3498db),
    Role.new('Diamond III', 14, 0x3498db),
    Role.new('Champion I', 15, 0x9b59b6),
    Role.new('Champion II', 16, 0x9b59b6),
    Role.new('Champion III', 17, 0x9b59b6),
    Role.new('Grand Champion I', 18, 0xe91e63),
    Role.new('Grand Champion II', 19, 0xe91e63),
    Role.new('Grand Champion III', 20, 0xe91e63),
    Role.new('Supersonic Legend', 21, 0xfefefe)
  ].freeze
  private_constant :ROLE_BY_RANK

  ROLE_BY_NAME = ROLE_BY_RANK.to_h { |role| [role.name, role] }.freeze
  private_constant :ROLE_BY_NAME
  #############################

  def self.roles(member, ranks)
    playlists = RLDB.server_playlists(member.server.id)

    all_rank_roles = all_roles(member.server)
    rank_role = if ranks.unranked?(playlists)
                  []
                else
                  best_rank = ranks.best(playlists).rank
                  [all_rank_roles.fetch(ROLE_BY_RANK.fetch(best_rank).name)]
                end
    return rank_role, all_rank_roles.values
  end

  def self.all_roles(server)
    roles = server.roles.select { |role| ROLE_BY_NAME.key?(role.name) }
    all_roles = roles.to_h { |role| [role.name, role] }
    create_missing_roles(server, all_roles)
    return all_roles
  end

  ##### PRIVATE #####

  def self.create_missing_roles(server, all_roles)
    return if all_roles.size >= ROLE_BY_NAME.size

    ROLE_BY_RANK.reverse_each { |role|
      next if all_roles.key?(role.name)

      all_roles[role.name] = server.create_role(name: role.name,
                                                colour: role.color,
                                                hoist: true,
                                                mentionable: true,
                                                permissions: 0)
    }
  end
  private_class_method :create_missing_roles
end
