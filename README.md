# ![Image of Tusk](./images/tusk.png)

[![Discord Chat](https://img.shields.io/discord/253308420919263233)](http://discordapp.com/channels/253308420919263233)

**`TuskBot` is a Rocket League Discord Bot focused on tracking player ranks and in-game stats.**

## Getting Started

### [Install TuskBot](https://discordapp.com/oauth2/authorize?&client_id=708694380869058600&permissions=470207553&scope=bot) on your discord server

## `Manage Roles` permission

You can choose to add the `Manage Roles` permission at any time and `TuskBot` will go to work adding these roles and assigning them to players upon execution of `!register` or `!ranks`.

Please note: The `Tusk` role needs to be placed above any role it's trying to modify.

### Rank Roles

If the `Manage Roles` permission is granted: `TuskBot` will create 19 rank roles.  These will be named:

- `Bronze I`
- `Bronze II`
- `Bronze II`
- `Silver I`
- `Silver II`
- `Silver III`
- `Gold I`
- `Gold II`
- `Gold III`
- `Platinum I`
- `Platinum II`
- `Platinum III`
- `Diamond I`
- `Diamond II`
- `Diamond III`
- `Champion I`
- `Champion II`
- `Champion III`
- `Grand Champion I`
- `Grand Champion II`
- `Grand Champion III`
- `Supersonic Legend`

Then: every time a `!register` or `!ranks` is executed, that player will be automatically assigned the role of their highest rank.

### Regional Roles

If the `Manage Roles` permission is granted: `TuskBot` will create 10 regional roles named:

- `JPN`
- `ASC`
- `ASM`
- `ME`
- `OCE`
- `SAF`
- `EU`
- `USE`
- `USW`
- `SAM`

Then: every time `[region]` is included in a `!register`, that player will be automatically assigned the role of their region.

Server owners (or users with the role `tusk_admin`) can choose to disable the creation and assignment of regional roles with `!disable_region_roles`.  If later you'd like to turn them back on, simply execute `!enable_region_roles`.

### Platform Roles

If the `Manage Roles` permission is granted: `TuskBot` will create 4 platform roles named:

- `ps`
- `xbox`
- `steam`
- `epic`

Then: every time a `!register` is executed, that player will automatically be assigned the role of their registered platform.

Server owners (or users with the role `tusk_admin`) can choose to disable the creation and assignment of platform roles with `!disable_platform_roles`.  If later you'd like to turn them back on, simply execute `!enable_platform_roles`.

## `Manage Nicknames` permission

If the `Manage Nicknames` permission is granted: every time a `[region]` is included in a `!register`, that player will have that region prefix added to their server Nickname, wrapped in brackets, such as `[USW]`.

Server owners (or users with the role `tusk_admin`) can choose to disable the assignment of regional prefixes to server Nicknames with `!disable_region_roles`.  If later you'd like to turn them back on, simply execute `!enable_region_roles`.

Note:  Due to Discord permissions, `Tusk` can't change the Nickname of server Owners and Administrators.

## Type `!help`

Once the bot is installed, you can type `!help` to see a list of all possible commands.

## Registering your Rocket League account

Most commands won't work unless you have registered your Rocket League account first:

```shell
!register <account-id>
          <platform(steam|epic|xbox|ps)>
          [region(JPN|ASC|ASM|ME|OCE|SAF|EU|USE|USW|SAM)]
```

### `<account-id> <platform>`

Both `<account-id>` and `<platform>` are required.

- **steam**:
  - You can use either:
    - The number at the end of a link like `http://steamcommunity.com/profiles/76561198257073170`.  In this case it would be `76561198257073170`.
    - The text at the end of a link like `https://steamcommunity.com/id/jubishop`.  In this case it would be `jubishop`.
  - Examples:
    - `!register 76561198257073170 steam`
    - `!register jubishop steam`

- **xbox**
  - Use your Gamertag:
    - `!register jubishop xbox`

- **ps**
  - Use your PSN:
    - `!register jubishop ps`

- **epic**
  - Use your Epic name:
    - `!register jubishop epic`

If your `<account-id>` has spaces in it, wrap it in quotes:

- `!register "My Name" epic`
- `!register "Cool Dude" steam`

### `[region]`

`[region]` is optional.  If you include a `[region]` when registering:

- `TuskBot` will assign you a role matching your region.  (If the `Manage Roles` permission has been granted)
- `TuskBot` will add a region prefix to the beginning of your Nickname containing your region.  (If the `Manage Nicknames` permission has been granted)

For example, if I registered with: `!register jubishop steam USW` and my nickname was `jubishop`, it'd become `[USW] jubishop` and I'd be given the role `USW`.

## Registering others

Server owners (or users with the role `tusk_admin`) can register people other than themselves.  The command is `!admin_register`, and the first param becomes a mention of the discord user to register.

- ***Steam/USE Example***: `!admin_register @jubi jubishop USE`
- ***XBox/USW Example***: `!admin_register @jubi jubishop xbox USW`
- ***PS/EU Example***: `!admin_register @jubi jubishop ps EU`
- ***Epic/OCE Example***: `!admin_register @jubi jubishop epic OCE`

### Updating all roles

Server owners (or users with the role `tusk_admin`) can also update the rank role of every registered user in the channel with `!update_all_roles`.

## Ranks

```shell
!ranks [member]
```

![Image of Ranks](./images/ranks.png)

- To get your own ranks, simply type `!ranks`
- To get the ranks of another registered player, follow the command with the name, nickname, or @mention of another discord member.
  - ***Example***: `!ranks jubi`
  - ***Example***: `!ranks @jubi`
- Every time a rank is checked, the role of that player will be updated to their current highest rank.  (If the `Manage Roles` permission has been granted)

## Stats from ballchasing.com

There are 2 commands for getting stats from ballchasing.com

### Series Stats

The `!series` command provides a way to view stats for the specific games where all the given players were playing together.  This makes for much more interesting comparisons.

```shell
!series [member1] [member2] [member3] ...
```

![Image of Series](./images/series.png)

- You can click the :arrow_left: and :arrow_right: buttons to flip between the different pages of statistics.
- To fetch your own stats, simply type `!series`
- This data is gathered from [ballchasing.com](http://ballchasing.com).  Stats are generated from the uploaded replays of the player who executes the `!series` command.  Your replays must be marked `public` for TuskBot to access them.  The easiest way to have all your replay files automatically uploaded is using [BakkesMod](https://bakkesmod.com/).  You can find instructions [here](https://ballchasing.com/doc/faq#upload).
- **If you do not upload your replays to [ballchasing.com](http://ballchasing.com), you will get 0 results from `!series`.**
- Because of API rate limits, `!series` will only work off the games you've played in the last 72 hours.
- If you provide a list of players it will display a table so their stats can be easily compared side by side.  You can fetch up to 6 players at a time.
- After a session of playing Doubles together, the image above was generated with the command:

```shell
!series @jubi @FezDispenser
```

### Alltime Series Stats

Every time a `!series` command is executed, `TuskBot` stores those replays in its own database.  The `!alltime` command uses those stored replays to show you the aggregate data of all the `!series` commands you've ever run.  So as long as you execute a `!series` command every 72 hours, you'll be able to use `!alltime` to get the complete stats of every game played since you began using `TuskBot`.

```shell
!alltime [member1] [member2] [member3] ...
```

- The display format for `!alltime` is exactly the same as `!series`.
- The `!alltime` command will only pull data from the stored replays inside its local database.  Only the `!series` command will get new data from [ballchasing.com](http://ballchasing.com)
- **If you do not upload your replays to [ballchasing.com](http://ballchasing.com), or you never run the `!series` command, you will get 0 results from `!alltime`.**

## Playlists

### Defining which playlists affect roles and ranks

By default, all playlists are considered when assigning roles based on rank. Server owners (or users with the role `tusk_admin`) can narrow this selection to any set of playlists they prefer using `!playlists`.  Playlist names are identified as:

- `standard`
- `doubles`
- `duel`
- `rumble`
- `dropshot`
- `hoops`
- `snow_day`
- `tournament`

List the playlists you care about with a `|` between each one.  For example, if you want to only assign roles based on the ranks in the `doubles`, `standard`, and `tournament` playlists:

```shell
!playlists doubles|standard|tournament
```

If you run `!playlists` with no parameters, it'll show you what playlists are currently being used.

If you want to go back to the default, run `!clear_playlists`.

## Custom Command Prefix

By default, `TuskBot` will accept commands when you address it directly via `@Tusk` or prefix your command with `!`.  Server owners can change this with `!set_command_prefix`.  To change it to `@`:

```shell
!set_command_prefix @
```

Now all commands will begin with `@`.  If you wanted to change it back to `!`:

```shell
@set_command_prefix !
```

If you ever forget what your command prefix is, you can address `@Tusk` directly to find out:

```shell
@Tusk command_prefix
```

Note: The maximum command prefix length is 8 characters.

## URL Commands

Use the `!help` command to learn about simple commands to get URLs to specific player pages on [ballchasing.com](http://ballchasing.com), [rocketleague.tracker.network](http://rocketleague.tracker.network), etc.

## Try it out before installing

You're welcome to [join the server](https://discord.gg/2YSmnyX) where `TuskBot` was developed and try it out for yourself.

## Bugs / Feedback

Feel free to file issues on [github](https://github.com/jubishop/Tusk/issues) or to hit me up in my [discord channel](https://discord.gg/2YSmnyX), I'm `@jubi`.
