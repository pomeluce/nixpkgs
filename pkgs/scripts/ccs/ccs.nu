#!/usr/bin/env nu
# --- 路径获取函数 ---
def get_settings_dir [] {
    $env.HOME | path join ".claude"
}
def get_settings_file [] {
    get_settings_dir | path join "settings.json"
}
def get_models_path [] {
    # 检查环境变量 CLAUDE_MODELS_PATH, 否则使用默认路径
    if "CLAUDE_MODELS_PATH" in $env { $env.CLAUDE_MODELS_PATH } else {
        $env.HOME | path join ".claude" "models.json"
    }
}
# --- 自动补全 ---
export def model_completions [] {
    let path = get_models_path
    if ($path | path exists) {
        open $path | get name | compact
    } else { [] }
}
# --- 内部逻辑 ---
def normalize [entry: record] {
    if ($entry | is-empty) {
        return {
            name: "unnamed"
            model: ""
            api_url: ""
            api_key: ""
        }
    }
    {
        name: (try {
            $entry | get name
        } catch { "unnamed" })
        model: (try {
            $entry | get model
        } catch { "" })
        api_url: (try {
            $entry | get api_url
        } catch { "" })
        api_key: (try {
            $entry | get api_key
        } catch { "" })
    }
}
def save_settings [new_env: record, source_name: string] {
    let s_dir = get_settings_dir
    let s_file = get_settings_file
    let existing = if ($s_file | path exists) { open $s_file } else {
        {
            env: {}
        }
    }
    let updated = $existing | merge {
        env: (try {
            $existing.env | default {} | merge $new_env
        } catch { $new_env })
        last_switch: {
            source: $source_name
            at: (date now | format date "%Y-%m-%d %H:%M:%S")
        }
    }
    if not ($s_dir | path exists) { mkdir $s_dir }
    $updated | to json | save -f $s_file
    $updated
}
# 解析 api_key, 支持 env:xxx 格式
def parse_api_key [api_key: string] {
    if ($api_key | str starts-with "env:") {
        let env_name = $api_key | str substring 4..
        try {
            $env | get $env_name
        } catch {
            # fallback 到默认环境变量
            try {
                $env | get CLAUDE_API_KEY
            } catch { "" }
        }
    } else if ($api_key | is-not-empty) {
        $api_key
    } else {
        # 空值 fallback 到默认环境变量
        try {
            $env | get CLAUDE_API_KEY
        } catch { "" }
    }
}
# 解析 model, 支持对象格式 { opus, sonnet, haiku } 或字符串
# 返回 { opus: "", sonnet: "", haiku: "" } 或错误
def parse_model [model, config_name: string] {
    if ($model | describe | str starts-with "record") {
        # 对象格式
        let required = ["opus", "sonnet", "haiku"]
        let missing = $required | where {|f|
            try {
                let v = $model | get $f
                ($v | is-empty) or ($v | into string | str trim | is-empty)
            } catch { true }
        }
        if ($missing | is-not-empty) {
            error make {
                msg: $"模型配置错误: \"($config_name)\" 的 model 字段不完整\n需要提供完整的三个字段: opus, sonnet, haiku\n当前缺失: ($missing | str join ', ')"
            }
        }
        {
            opus: ($model | get opus | into string)
            sonnet: ($model | get sonnet | into string)
            haiku: ($model | get haiku | into string)
        }
    } else {
        error make {
            msg: $"模型配置错误: \"($config_name)\" 的 model 字段必须是对象格式 { opus, sonnet, haiku }"
        }
    }
}
# 安全获取字符串值, 如果 entry 中没有则 fallback 到环境变量
def get_or_fallback [entry: record, field: string, env_var: string] {
    let val = try {
        $entry | get $field
    } catch { null }
    if ($val | is-not-empty) {
        $val | into string
    } else {
        try {
            $env | get $env_var
        } catch { "" } | into string
    }
}
# --- 导出子命令 ---
# 初始化 settings.json
export def --env init [model_name?: string, --force] {
    let s_file = get_settings_file
    if ($s_file | path exists) and (not $force) {
        print $"(ansi yellow)settings.json 已存在. 使用 --force 强制初始化.(ansi reset)"
        return
    }
    use-model $model_name
}
# 切换模型配置
export def --env "use-model" [model_name?: string] {
    let models_path = get_models_path
    let models_data = if ($models_path | path exists) { open $models_path } else { [] }
    # 如果 models.json 不存在或为空, fallback 到环境变量
    if ($models_data | is-empty) {
        let final_env = {
            ANTHROPIC_BASE_URL: (try {
                $env | get CLAUDE_API_URL
            } catch { "" })
            ANTHROPIC_AUTH_TOKEN: (try {
                $env | get CLAUDE_API_KEY
            } catch { "" })
            ANTHROPIC_MODEL: (try {
                $env | get CLAUDE_MODEL_NAME
            } catch { "" })
            ANTHROPIC_DEFAULT_OPUS_MODEL: (try {
                $env | get CLAUDE_MODEL_NAME
            } catch { "" })
            ANTHROPIC_DEFAULT_SONNET_MODEL: (try {
                $env | get CLAUDE_MODEL_NAME
            } catch { "" })
            ANTHROPIC_DEFAULT_HAIKU_MODEL: (try {
                $env | get CLAUDE_MODEL_NAME
            } catch { "" })
            CLAUDE_CODE_SUBAGENT_MODEL: (try {
                $env | get CLAUDE_MODEL_NAME
            } catch { "" })
        }
        save_settings $final_env "default env"
        load-env $final_env
        print $"(ansi cyan)models.json 不存在, 已使用环境变量默认值(ansi reset)"
        return
    }
    let target = if ($model_name | is-not-empty) {
        let matches = $models_data | where {|it| $it.name? == $model_name}
        if ($matches | is-empty) {
            print $"(ansi yellow)未找到模型配置: ($model_name)(ansi reset)"
            print $"(ansi cyan)可用模型:(ansi reset)"
            for m in ($models_data | get name) {
                print $"  - ($m)"
            }
            return
        }
        $matches | first
    } else {
        # 查找默认模型
        let defaults = $models_data | where {|it| $it.default? == true}
        if ($defaults | is-not-empty) {
            $defaults | first
        } else {
            $models_data | first
        }
    }
    let norm = normalize $target
    # 解析 model 字段
    let model_config = try {
        parse_model $norm.model $norm.name
    } catch {|e|
        print $"(ansi red)($e.msg)(ansi reset)"
        return
    }
    # 解析 api_key 字段
    let api_key_val = parse_api_key $norm.api_key
    # 构建最终环境变量
    let final_env = {
        ANTHROPIC_BASE_URL: (get_or_fallback $norm "api_url" "CLAUDE_API_URL")
        ANTHROPIC_AUTH_TOKEN: $api_key_val
        ANTHROPIC_MODEL: $model_config.opus
        ANTHROPIC_DEFAULT_OPUS_MODEL: $model_config.opus
        ANTHROPIC_DEFAULT_SONNET_MODEL: $model_config.sonnet
        ANTHROPIC_DEFAULT_HAIKU_MODEL: $model_config.haiku
        CLAUDE_CODE_SUBAGENT_MODEL: $model_config.haiku
    }
    if ($final_env.ANTHROPIC_DEFAULT_OPUS_MODEL == "" and $final_env.ANTHROPIC_BASE_URL == "") { error make {msg: "无法确定模型配置, 请检查 models.json"} }
    save_settings $final_env $norm.name
    load-env $final_env
    print $"(ansi cyan)已切换至: ($norm.name)(ansi reset)"
}
# --- 脚本入口 ---
def main [...args] {
    if ($args | is-empty) { use-model "" } else if ($args.0 == "init") {
        let rest = $args | skip 1
        if ($rest | any {|x| $x == "--force"}) {
            init ($rest | where {|x| $x != "--force"} | first | default "") --force
        } else { init ($rest | first | default "") }
    } else { use-model ($args | first) }
}
