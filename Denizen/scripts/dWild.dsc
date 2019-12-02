# +--------------------
# |
# | dWild
# |
# | Allows players to be teleported to a random
# | location, a minimum (and maximum) distance 
# | from the world spawn.
# |
# | This uses MC world spawn, not
# | essentials/other plugins
# |
# +----------------------
#
# @author GoMinecraft ( Discord: GoMinecraft#1421 )
# @date 2019/12/01
# @denizen-build REL-1696
# @script-version 0.5.0
#
# Usage - Alias: /wild:
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

dWild_version:
  type: yaml data
  version: 0.5.0

  # Init process
dWild_init:
  type: task
  debug: true
  script:
  - if <server.has_file[../dWild/config.yml]>:
    - ~yaml load:../dWild/config.yml id:dWild_config
    - announce to_console "[dWild] Loaded config.yml"

  - if <yaml.list.contains[dWild_config]>:
    - announce to_console "<green>Loaded dWild config successfully."
    - flag server dWildLoaded:true
  - else:
    - announce to_console "<red>One or more config files failed to load. Please check your console log."
    - flag server dWildLoaded:false

dWild_cmd:
  type: command
  debug: true
  name: dwild
  aliases:
  - wild
  permission: dwild.wild
  script:

  # Sling an error if the config didn't load.
  - if !<server.flag[dWildLoaded]>:
    - narrate "An error has occured in dWild."
    - stop

  # If you have the permission.. version!
  - if <context.args.get[1]> == version && ( <player.has_permission[dwild.version]||false> || <context.server> ):
    - narrate "<red>dWild <green>v<script[dWild_version].yaml_key[version]>"
    - stop
  - if <context.args[1]> == reload && ( <player.has_permission[dwild.reload]||false> || <context.server> )
    - inject dWild_init
    - narrate "<green>RandomDeathMessages has been reloaded."
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
      - if <server.match_player[<context.args.get[1]>]>:
        - define target:<server.match_player[<context.args.get[1]>]>
      - else:
        - narrate "<context.args.get[1] not found."
    - else:
      - narrate "You do not have permission to use wild on other players."
      - stop

  - if <player.has_permission[dwild.wild]>:

    - define maxDistFromSpawn:<yaml[dWild_config].read[max-teleport-distance]>

    - if <yaml[dWild_config].read[use-worldborder]>:
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
  - else:
    - narrate "<red>You do not have permission to run that command."
    - stop

  - define randZCoords:<util.random.int[<[safeTeleportDistNegative]>].to[<[safeTeleportDistPositive]>]>
  - define randXCoords:<util.random.int[<[safeTeleportDistNegative]>].to[<[safeTeleportDistPositive]>]>

  - if <yaml[dWild_config].read[use-effects]>:
    - playeffect sneeze <player.location.above.forward> quantity:500 offset:0.6
  - teleport <[target]> l@<[randXCoords]>,255,<[randZCoords]>,<[target].location.world>
  - flag <[target]> freeFalling:true duration:<yaml[dWild_config].read[immunity-seconds]>
  - flag <[target]> dWildRecent:true duration:<yaml[dWild_config].read[command-cooldown]>


dWild_events:
  type: world
  debug: true
  events:
    on reload scripts:
      - inject dWild_init
    on server start:
      - inject dWild_init

    on player damaged by FALL bukkit_priority:LOWEST:
      - if <player.has_flag[freeFalling]>:
        - flag <player> freeFalling:!
        - determine cancelled

    on entity starts gliding:
      - if <player.has_flag[freeFalling]>:
        - flag <player> freeFalling:!
