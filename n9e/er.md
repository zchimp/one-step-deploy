```Mermaid
erDiagram
    %% ========== 权限组织模块 ==========
    USER {
        bigint id PK
        varchar role  FK "关联role表name，一个用户只能一个角色"
    }
    ROLE {
        varchar name PK
    }
    USER_GROUP {
        bigint id PK "user_group(团队)"
        varchar name
    }
    USER_GROUP_USER {
        bigint id PK "中间表 M:N user <-> user_group"
        bigint user_id FK
        bigint user_group_id FK
    }
    BUSI_GROUP {
        bigint id PK "业务组，核心租户单元"
        varchar name
    }
    BUSI_GROUP_MEMBER {
        bigint id PK "中间表 M:N user_group <-> busi_group"
        bigint busi_group_id FK
        bigint user_group_id FK
        char perm_flag "ro/rw，关系属性存中间表"
    }

    %% ========== 大盘模块 ==========
    BOARD {
        bigint id PK "新版大盘元数据"
        bigint group_id FK "busi_group.id"
    }
    BOARD_PAYLOAD {
        bigint id PK "1:1 和 board.id一一对应，存大盘大JSON"
        mediumtext payload
    }
    CHART_SHARE {
        bigint id PK "共享图表模板，独立，不关联board"
    }

    %% ========== 数据源 ==========
    DATASOURCE {
        bigint id PK
        bigint group_id FK "归属业务组"
    }

    %% ========== 告警配置 ==========
    ALERT_RULE {
        bigint id PK "告警规则配置"
        bigint group_id FK "busi_group.id"
    }
    ALERT_MUTE {
        bigint id PK "告警屏蔽规则"
        bigint group_id FK
    }
    ALERT_SUBSCRIBE {
        bigint id PK "告警订阅二次分发"
        bigint group_id FK
    }
    RECORDING_RULE {
        bigint id PK "记录规则"
        bigint group_id FK
    }
    METRIC_VIEW {
        bigint id PK "指标视图模板"
    }
    ALERT_AGGR_VIEW {
        bigint id PK "告警聚合视图模板"
    }

    %% ========== 告警事件冷热分离 ==========
    ALERT_CUR_EVENT {
        bigint id PK "活跃告警（告警中）"
        bigint rule_id FK "alert_shturl."
        varchar target_ident FK "target.ident 逻辑关联"
    }
    ALERT_HIS_EVENT {
        bigint id PK "全部历史告警，id与cur_event共用"
        bigint rule_id FK "alert_shturl."
        varchar target_ident FK "target.ident 逻辑关联"
    }

    %% ========== Agent主机元数据 ==========
    TARGET {
        bigint id PK
        varchar ident UK "agent唯一标识"
        bigint group_id FK "busi_group.id"
    }

    %% ========== 关系连线 ==========
    USER }o--o{ USER_GROUP : "M:N 用户-团队(中间表user_group_user)"
    USER_GROUP }o--o{ BUSI_GROUP : "M:N 团队-业务组(中间表busi_group_member，携带ro/rw)"
    USER ||--o{ ROLE : "N:1 用户角色，user.role存role.name，单角色"

    BUSI_GROUP ||--o{ BOARD : "1:N 业务组拥有多个大盘"
    BOARD ||--|| BOARD_PAYLOAD : "1:1 大盘元数据 ↔ 大盘完整JSON"
    BUSI_GROUP ||--o{ DATASOURCE : "1:N 业务组多个数据源"

    BUSI_GROUP ||--o{ ALERT_RULE : "1:N 业务组多条告警规则"
    BUSI_GROUP ||--o{ ALERT_MUTE : "1:N 业务组多条屏蔽规则"
    BUSI_GROUP ||--o{ ALERT_SUBSCRIBE : "1:N 业务组多条订阅规则"
    BUSI_GROUP ||--o{ RECORDING_RULE : "1:N 业务组多条记录规则"
    BUSI_GROUP ||--o{ TARGET : "1:N 业务组多台agent主机"

    ALERT_RULE ||--o{ ALERT_CUR_EVENT : "1:N 规则产生多条活跃告警事件"
    ALERT_RULE ||--o{ ALERT_HIS_EVENT : "1:N 规则产生多条历史告警事件"

    TARGET ||--o{ ALERT_CUR_EVENT : "1:N 逻辑关联 target.ident = alert_cur_event.target_ident"
    TARGET ||--o{ ALERT_HIS_EVENT : "1:N 逻辑关联 target.ident = alert_his_event.target_ident"

    ALERT_CUR_EVENT ||--|| ALERT_HIS_EVENT : "1:1 id完全相同，cur是his子集(未恢复告警)"
```