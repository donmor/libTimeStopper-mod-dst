local function LIMBO(tbl)
    return ChooseTranslationTable(tbl)
end

name = "libTimeStopper"
version = "1.0.0"
description = LIMBO({
[[
libTimeStopper - Time stopping library

* I'm a modding starter so that there may be undiscovered bug
* Lots of modified APIs so be attention to compatibility

Use this library to build mods of time-stopping psychics or items
- Configurable powerful mode (Stopping the WHOLE map, can lead to performance problems)
- Configurable Invincibility of stopped entities (depends on characteristics, etc.)
See Readme.md for details.
]], ["zh"] = [[
libTimeStopper - 时间停止支持库

※MOD制作新手, 请注意潜在的bug
※大量API修改, 请注意兼容性问题

使用本API快速构建相互兼容的时间停止能力者或道具
·可配置强力模式(全图时停, 极大消耗性能)
·可配置时停对象是否无敌(取决于人物设定等)
附说明文档(Readme.md)
]], ["zhr"] = [[
libTimeStopper - 时间停止支持库

※MOD制作新手, 请注意潜在的bug
※大量API修改, 请注意兼容性问题

使用本API快速构建相互兼容的时间停止能力者或道具
·可配置强力模式(全图时停, 极大消耗性能)
·可配置时停对象是否无敌(取决于人物设定等)
附说明文档(Readme.md)
]]})
author = "donmor"
forumthread = ""
api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = true 
icon_atlas = "modicon.xml"
icon = "modicon.tex"
server_filter_tags = {
    "utility",
}
bugtracker_config = {
    email = "donmor3000@hotmail.com",
    upload_client_log = true,
    upload_server_log = true,
}
configuration_options =
{
    {
        name = "powerful_mode",
        label = LIMBO({
            "Powerful mode",
            ["zh"] = "强力模式",
            ["zhr"] = "强力模式",
        }),
        options =
        {
            {
                description = LIMBO({
                    "Enable",
                    ["zh"] = "开启",
                    ["zhr"] = "开启",
                }),
                data = true,
                hover = LIMBO({
                    "Stop the whole world(Too many lags, do on your own risk!)",
                    ["zh"] = "时停整个世界(极卡, 后果自负!)",
                    ["zhr"] = "时停整个世界(极卡, 后果自负!)",
                })
            },
            {
                description = LIMBO({
                    "Disable",
                    ["zh"] = "关闭",
                    ["zhr"] = "关闭",
                }),
                data = false,
                hover = LIMBO({
                    "Apply to current screen",
                    ["zh"] = "时停屏幕范围",
                    ["zhr"] = "时停屏幕范围",
                }),
            },
        },
        default = false,
    },
    
    {
        name = "invincible_foe",
        label = LIMBO({
            "Invincible foe",
            ["zh"] = "目标无敌",
            ["zhr"] = "目标无敌",
        }),
        options =
        {
            {
                description = LIMBO({
                    "Enable",
                    ["zh"] = "开启",
                    ["zhr"] = "开启",
                }),
                data = true,
                hover = LIMBO({
                    "Make entities invincible if time-stopped",
                    ["zh"] = "被停止的实体无敌",
                    ["zhr"] = "被停止的实体无敌",
                }),
            },
            {
                description = LIMBO({
                    "Disable",
                    ["zh"] = "关闭",
                    ["zhr"] = "关闭",
                }),
                data = false,
                hover = LIMBO({
                    "Normally take damage",
                    ["zh"] = "被停止的实体正常受到伤害",
                    ["zhr"] = "被停止的实体正常受到伤害",
                }),
            },
        },
        default = false,
    }
}
