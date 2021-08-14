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
- Configurable invincibility of stopped entities (depends on characteristics, etc.)
- Configurable global grey screen effect
See Readme.md for details.
]], ["zh"] = [[
libTimeStopper - 时间停止支持库

※MOD制作新手, 请注意潜在的bug
※大量API修改, 请注意兼容性问题

使用本API快速构建相互兼容的时间停止能力者或道具
·可配置强力模式(全图时停, 极大消耗性能)
·可配置时停对象是否无敌(取决于人物设定等)
·可配置时停时使用全局灰屏特效
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
        name = "performance",
        label = LIMBO({
            "Time-stopping mode",
            ["zh"] = "时间停止模式",
        }),
        options =
        {
            {
                description = LIMBO({
                    "Performance mode",
                    ["zh"] = "性能模式",
                }),
                data = 50,
                hover = LIMBO({
                    "Apply to current screen, for low-end devices",
                    ["zh"] = "时停屏幕范围, 适用于低端机型",
                }),
            },
            {
                description = LIMBO({
                    "Normal mode",
                    ["zh"] = "普通模式",
                }),
                data = 500,
                hover = LIMBO({
                    "Apply to a wide range, for most devices",
                    ["zh"] = "时停较大范围, 适用于大部分机型",
                }),
            },
            {
                description = LIMBO({
                    "Powered mode",
                    ["zh"] = "强力模式",
                }),
                data = 2000,
                hover = LIMBO({
                    "Apply to a wide range, for servers and high-end devices",
                    ["zh"] = "时停更大范围, 适用于服务器及高端机型",
                }),
            },
            {
                description = LIMBO({
                    "Extreme mode",
                    ["zh"] = "极限模式",
                }),
                data = 9001,
                hover = LIMBO({
                    "Stop the whole world(Many lags, do on your own risk!)",
                    ["zh"] = "时停整个世界(很卡, 风险自负!)",
                })
            },
        },
        default = 500,
    },

    {
        name = "ignore_shadow",
        label = LIMBO({
            "Ignore shadow creature",
            ["zh"] = "排除影怪",
        }),
        options =
        {
            {
                description = LIMBO({
                    "Enable",
                    ["zh"] = "开启",
                }),
                data = true,
                hover = LIMBO({
                    "Nightmare creatures won't be stopped (only those related to sanity)",
                    ["zh"] = "影怪不受时停影响(仅限与理智相关的)",
                })
            },
            {
                description = LIMBO({
                    "Disable",
                    ["zh"] = "关闭",
                }),
                data = false,
                hover = LIMBO({
                    "Nightmare creatures could be stopped",
                    ["zh"] = "所有影怪可被时停",
                }),
            },
        },
        default = true,
    },
    
    {
        name = "ignore_wortox",
        label = LIMBO({
            "Ignore Wortox",
            ["zh"] = "排除沃拓克斯",
        }),
        options =
        {
            {
                description = LIMBO({
                    "Enable",
                    ["zh"] = "开启",
                }),
                data = true,
                hover = LIMBO({
                    "Wortox won't be stopped",
                    ["zh"] = "沃拓克斯不受时停影响",
                })
            },
            {
                description = LIMBO({
                    "Disable",
                    ["zh"] = "关闭",
                }),
                data = false,
                hover = LIMBO({
                    "Wortox could be stopped",
                    ["zh"] = "沃拓克斯可被时停",
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
        }),
        options =
        {
            {
                description = LIMBO({
                    "Enable",
                    ["zh"] = "开启",
                }),
                data = true,
                hover = LIMBO({
                    "Make entities invincible if time-stopped",
                    ["zh"] = "被停止的实体无敌",
                }),
            },
            {
                description = LIMBO({
                    "Disable",
                    ["zh"] = "关闭",
                }),
                data = false,
                hover = LIMBO({
                    "Normally take damage",
                    ["zh"] = "被停止的实体正常受到伤害",
                }),
            },
        },
        default = false,
    },

    {
        name = "greyscreen",
        label = LIMBO({
            "Global grey screen effect",
            ["zh"] = "全局灰屏特效",
        }),
        options =
        {
            {
                description = LIMBO({
                    "Enable",
                    ["zh"] = "开启",
                }),
                data = true,
                hover = LIMBO({
                    "Screen greys on time stopped",
                    ["zh"] = "时间停止时屏幕变灰",
                }),
            },
            {
                description = LIMBO({
                    "Disable",
                    ["zh"] = "关闭",
                }),
                data = false,
                hover = LIMBO({
                    "Normal vision",
                    ["zh"] = "正常视效",
                }),
            },
        },
        default = true,
    }
}
