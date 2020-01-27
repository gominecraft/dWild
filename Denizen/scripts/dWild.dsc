# +--------------------
# |
# | dWild
# |
# | Allows players to be teleported to a random
# | location, a maximum distance from the
# | world spawn.
# |
# +----------------------
#
# @author GoMinecraft ( Discord: GoMinecraft#1421 )
# @date 2019/12/03
# @denizen-build DEV-4511+
# @script-version 1.1.1
#
# Usage - Alias: /wild, /rtp:
# /dwild [player]
# /dwild version - Shows the version
# /dwild reload - Reloads the config.yml
#
# Permissions:
# dwild.wild - Lets a player use /wild
# dwild.wild.other # Lets a player use /wild on other players
# dwild.version - Shows the dwild version number
#
# Recommended usage:
#  * Setup zone-based permissions and only allow /wild to be
# used in spawn or set a high command-cooldown

# ---- Don't edit below here unless you know what you're doing.
# ---- I definitely don't know what I'm doing.

dWildVersion:
  type: yaml data
  version: 1.1.0

  # Init process
dWildInit:
  type: task
  debug: false
  script:
  - if <server.has_file[../dWild/config.yml]>:
    - ~yaml load:../dWild/config.yml id:dWildConfig
    - announce to_console "[dWild] Loadeding config.yml"

  - if <yaml.list.contains[dWildConfig]>:
    - announce to_console "[dWild] Loaded dWild config successfully."
    - flag server dWildLoaded:true
  - else:
    - announce to_console "[dWild] One or more config files failed to load. Please check your console log."
    - flag server dWildLoaded:false

dWildCommand:
  type: command
  debug: false
  name: dwild
  aliases:
  - wild
  - rtp
  permission: dwild.wild
  script:

  # Sling an error if the config didn't load.
  - if !<server.flag[dWildLoaded]>:
    - narrate "An error has occured in dWild."
    - stop

  # If you have the permission.. version!
  - if <context.args.get[1]||null> == version && ( <player.has_permission[dwild.version]> || <context.server> ):
    - narrate "<red>dWild <green>v<script[dWildVersion].yaml_key[version]>"
    - stop
  - if <context.args.get[1]> == reload && ( <player.has_permission[dwild.reload]> || <context.server> )
    - inject dWild_init
    - narrate "<green>dWild has been reloaded."
    - stop

  # Let ops bypass the command-cooldown
  - if <player.has_flag[dWildRecent]> && !<player.is_op>:
    - narrate "<red>You must wait <player.flag[dWildRecent].expiration.formatted> before you can use this command again."
    - stop

  # Run dwild or dwild [player]
  - if <context.args.get[1]||null> == null:
    - define target:<player>
  - else:
    - if <player.has_permission[dwild.other]>:
      - if <server.match_player[<context.args.get[1]>]> != null:
        - narrate "Found player ..."
        - define target:<server.match_player[<context.args.get[1]>]>
      - else:
        - narrate "<context.args.get[1]> not found."
    - else:
      - narrate "You do not have permission to use wild on other players."
      - stop

  - define maxDistFromSpawn:<yaml[dWildConfig].read[max-teleport-distance]>
  - define blacklistBiomes:<yaml[dWildConfig].read[blacklist-biomes]>

  - if <yaml[dWildConfig].read[use-worldborder]>:
    - define border:<player.location.world.border_size.div[2]>
    - if <[border]> > 10000:
      - define safeTeleportDistPositive:<[border].sub[1000]>
      - define safeTeleportDistNegative:<[safeTeleportDistPositive].mul[-1]>
    - else:
      - define safeTeleportDistPositive:<[border].sub[<[border].mul[0.10]>]>
      - define safeTeleportDistNegative:<[safeTeleportDistPositive].mul[-1]>
  - else:
    - define safeTeleportDistPositive:<[maxDistFromSpawn].sub[<[maxDistFromSpawn].as_element.mul[0.10]>]>
    - define safeTeleportDistNegative:<[safeTeleportDistPositive].to_element.mul[-1]>

  - define foundChunk:false
  - define loops:0

  - while !<[foundChunk]> && ( <[loops]> <= 5 ):
    - define loops:++
    - define randXCoords:<util.random.int[<[safeTeleportDistNegative]>].to[<[safeTeleportDistPositive]>]>
    - define randZCoords:<util.random.int[<[safeTeleportDistNegative]>].to[<[safeTeleportDistPositive]>]>
    - if <yaml[dWildConfig].read[blacklist-biomes].size> > 0:
      - define loc:<location[<[randXCoords]>,1,<[randZCoords]>,<player.location.world>]>
      - chunkload add <[loc].chunk> duration:1t
      - if !<[loc].biome.contains_any[<[blacklistBiomes]>]>:
        - define foundChunk:true
    - else:
      - define foundChunk:true
    - wait 5t

  - if !<[foundChunk]> || <[loops]> >= 5:
    - narrate "<gold>Failed to find a safe place to send you. Try again!"
    - stop

  - if <yaml[dWildConfig].read[use-effects]>:
    - playeffect sneeze <player.location.above.forward> quantity:25 offset:0.6
  - teleport <[target]> <[randXCoords]>,255,<[randZCoords]>,<[target].location.world>
  - flag <[target]> dWildFreeFalling:true duration:<yaml[dWildConfig].read[immunity-seconds]>
  - flag <[target]> dWildRecent:true duration:<yaml[dWildConfig].read[command-cooldown]>

dWild_events:
  type: world
  debug: false
  events:
    on reload scripts:
      - inject dWildInit
    on server start:
      - inject dWildInit

    on player damaged by FALL bukkit_priority:LOWEST:
      - if <player.has_flag[dWildFreeFalling]>:
        - flag <player> dWildFreeFalling:!
        - determine cancelled

    on entity starts gliding:
      - if <player.has_flag[dWildFreeFalling]>:
        - flag <player> dWildFreeFalling:!
