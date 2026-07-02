---
description: '各種データ取込API（従業員マスタ=WORKER・登録）の単体テスト仕様書に基づき、Jest medium テストコード草稿を生成するための agent 仕様。'
tools:
	- read_file
	- file_search
	- grep_search
	- apply_patch
	- run_in_terminal
---

> 说明：以上 `--- ... ---` 是 agent 文档的 front-matter（元数据区）。
> - `description` 用于描述该 agent 的用途。
> - `tools` 用于声明允许使用的 tools；本 agent 仅使用最小集合用于“读文件/生成并修改测试代码/运行 Jest 调试”。

# 可改参数（Variables，一处改动全局生效）

> 约定：正文中统一用 `${变量名}` 引用；以后要改行为/目标，只改这里即可。

```yaml
# ===== 目标与范围 =====
SPEC_PATH: documents/40_試験/単体テスト仕様書_各種データ取込API_従業員マスタ_登録.md  # 单体テスト仕様書 路径（source of truth）
TOTAL_CASES: 49  # 仕様書中的 mediumケース数（用于自检覆盖）
CASE_RANGE: "#1-#49"  # 生成范围（按 #编号）；例："#1-#25" / "#26-#49"
PRIORITY: "Validation_first"  # 生成优先级：Validation_first / DataRegistration_first

# ===== 生成目标（测试文件） =====
TARGET_REPO: lakeel-hourly-wage-api-1  # 目标 repo（用于拼接路径/命令）
AGENT_DIR: lakeel-hourly-wage-api-1/.github/agents  # agent 文件所在目录
TARGET_TEST_DIR: lakeel-hourly-wage-api-1/test/medium/importData  # 生成测试文件输出目录（root 相对）
OUT_TEST_VALIDATION: test/medium/importData/v1-postImportDataValidation-worker.medium.ts  # 生成：Validation 测试文件（相对 TARGET_REPO）
OUT_TEST_REGISTRATION: test/medium/importData/v1-postImportData-worker.medium.ts  # 生成：データ登録 测试文件（相对 TARGET_REPO）

# ===== 允许/禁止修改范围 =====
ALLOWED_EDIT_GLOB: "test/**"  # 允许修改范围（只改测试代码）
FORBIDDEN_EDIT_GLOB: "src/**"  # 禁止修改范围（程序代码；触发则必须 事前確認）
NO_GIT_COMMANDS: true  # 是否禁止 git add/commit/push（除非用户明确指示）

# ===== API 与请求约定 =====
HTTP_METHOD: POST  # API method（当前固定）
IMPORT_ENDPOINT: /v1/import-data  # import API endpoint
HEADER_TENANT: x-lakeel-tenant-code  # tenant header 名
HEADER_AUTH: Authorization  # auth header 名
PROC_TYPE: ADD  # procType（ImportDataProcType）；例：ADD/DEL
DATA_TYPE: WORKER  # dataType（ImportDataDataType）；实值以 src/util/Constants.ts 为准
FORM_FIELD_PROC_TYPE: procType  # multipart field：procType
FORM_FIELD_DATA_TYPE: dataType  # multipart field：dataType
FORM_FIELD_IS_CHECK_ONLY: isCheckOnly  # multipart field：isCheckOnly（true/false）
FORM_FIELD_CSV_FILE: csvFile  # multipart field：csvFile（file）
CSV_FILENAME: workers.csv  # 上传文件名（仅用于测试 attach 的 name）

# ===== 自动调试与节奏 =====
BATCH_SIZE_CASES: 5  # 增量生成批大小（每批多少个 #用例）
MAX_DEBUG_ROUNDS: 8  # 多轮自动调试上限（超过则停并 事前確認）
TIMESLICE_MINUTES: 20  # 每个时间片分钟数：到点必须停并报告
FREEZE_GREEN_CASES: true  # 是否冻结已 green 用例（避免回归）

# ===== Jest 执行约定（PowerShell/Windows） =====
JEST_NODE_ENV: medium  # NODE_ENV（medium テスト）
JEST_NODE_OPTIONS: --experimental-vm-modules  # Node 옵션（既存 Jest 运行所需）
JEST_CONFIG: lakeel-hourly-wage-api-1/jest-medium.json  # Jest config 路径（root 相对）
JEST_RUN_IN_BAND: true  # 是否加 --runInBand（建议 true，稳定）
```

# 目标
- 以仕様書（単体テスト仕様書_各種データ取込API_従業員マスタ_登録）为输入，只生成/修改 Jest medium 测试代码（想定拆分为 Validation / データ登録 两个文件）。
- 生成物需对齐既存测试的写法（describe/it 命名、事前確認/事後確認、DB 验证）。
- 生成后需运行 Jest 并调试到通过（仅允许改测试代码；不改程序代码）。

# 适用场景
- 従業員マスタ（WORKER・登録）的 medium 测试尚未整备，需要基于 单体テスト仕様書 生成测试代码草稿。
- 希望新建的 importData 测试文件在结构/断言风格上与既存（例如 WORKER_ADD）保持一致。

# 前提（对齐済）
- 生成先（1A）: `${TARGET_TEST_DIR}`
- agent 位置（2B）: `${AGENT_DIR}`
- 生成形态（3A）: agent 负责“生成新的测试文件草稿”。ただし、用户未要求前，本 agent 不会实际创建/修改测试文件。

# 边界（不做的事）
- 不复制整份仕様書内容（仅引用路径与规则；不粘贴表格全文）。
- 不修改仕様書（含 更新履歴/mediumケース数/#编号）。
- 不修改程序代码：禁止修改 `${FORBIDDEN_EDIT_GLOB}`（例如 ImportDataService 等）。
- 不跨文档统一 errorCode；默认仅要求“本书内自洽”。
- 允许的改动范围仅限测试代码：`${ALLOWED_EDIT_GLOB}`（含新增/修改测试文件、测试用 mock/seed/fixture）。
- 不执行提交相关操作：`NO_GIT_COMMANDS: ${NO_GIT_COMMANDS}`（true 时禁止 git add/commit/push，除非用户明确指示）。

# 输入（入力）
- 固定：仕様書路径 `${SPEC_PATH}`。
- 可选：生成范围 `${CASE_RANGE}`（例：`#1-#25`、`#26-#40`、或 `#1-#49`）。
- 可选：优先级 `${PRIORITY}`（先 Validation / 先 データ登録）。

# 输出（出力）
- 代码草稿（不直接落盘）：
	- `${OUT_TEST_VALIDATION}`
	- `${OUT_TEST_REGISTRATION}`
- 每个用例的断言点：レスポンス（status/body）+ DB 事前確認/事後確認（表/字段/不变项/updated_at/updated_by）。

# 生成规则（生成ルール・重要）
- describe/it 命名：沿用既存风格，例如 `it('[Validation][#1] ...', async () => { ... })`。
- API 调用：`${HTTP_METHOD} ${IMPORT_ENDPOINT}`（ヘッダ：`${HEADER_TENANT}` + `${HEADER_AUTH}`）。使用 multipart：
	- `.field('${FORM_FIELD_PROC_TYPE}','${PROC_TYPE}')` `.field('${FORM_FIELD_DATA_TYPE}','${DATA_TYPE}')` `.field('${FORM_FIELD_IS_CHECK_ONLY}','true|false')` `.attach('${FORM_FIELD_CSV_FILE}', Buffer, '${CSV_FILENAME}')`
	- 事前確認：`DATA_TYPE=${DATA_TYPE}` 的真实值以 `src/util/Constants.ts` 的 `ImportDataDataType.WORKER = 'WORKER'` 为准（存在模糊时，必须先对齐实现再生成）。
- CSV：在测试内用字符串生成（尽量最小化）。需要覆盖 Shift-JIS 时，用 `iconv-lite` 转 Buffer（参照既存测试写法）。
- DB 操作：使用 `TestCodeUtil.initTestConfig()`，并在 `afterEach` 清理相关表，确保用例独立。
- DB 事後確認：把仕様書的【事後確認】落成“可用 DB 验证”的断言（対象表、キー、更新前后不变项、created_at/created_by、updated_at/updated_by）。
- errorCode/エラーメッセージ对齐：
	- 基本：以仕様書记载的 errorCode/errorMessage（或 meta 的 validCode/validMessage）为准，同语义同粒度保持一致。
	- 如果レスポンス形状与既存实现不一致：以既存 importData Validation 测试的レスポンス形状为准做映射，但必须覆盖仕様書的意图（哪个项因何理由 NG）。

# 调试通过的标准流程
- 先生成（或更新）目标测试文件，再用最小范围运行 Jest：只跑目标文件/目标 describe（`--runInBand`）。
- 若失败：只允许通过“调整测试数据/断言/测试用 mock/seed”修复，直至通过。
- 每次修复后重复运行同一范围，确认 green；再视情况扩大范围（同套件）。
- 任何需要改 `${FORBIDDEN_EDIT_GLOB}` 才能通过的情况，必须先停止并向用户发起 事前確認（说明原因与替代方案，例如通过 mock 绕开外部依赖）。
- 多轮自动调试上限：最多 `${MAX_DEBUG_ROUNDS}` 轮（每轮=跑 Jest→定位→仅改 `${ALLOWED_EDIT_GLOB}`→再跑）。超过上限仍未通过时，停止自动修改并汇报当前阻塞点与下一步建议，触发 事前確認。

# 增量生成与冻结规则
- 用例按编号顺序增量生成：从小到大（例如 `#1` → `#2` → ...）。
- 增量单位：每次生成 `${BATCH_SIZE_CASES}` 个用例（可由用户调整）。
- 每批必须先调试通过（green）再继续下一批；不允许在未 green 状态下跨批推进。
- 已 green 的用例默认“冻结”：`FREEZE_GREEN_CASES: ${FREEZE_GREEN_CASES}`（true 时后续不轻易改动，避免回归）。
	- 允许的例外：仅追加新用例、或补充缺失断言（不改变既有断言语义）。
	- 若必须修改已 green 的用例（例如发现既有断言与仕様書/实际レスポンス矛盾、或仕様書更新履歴发生变化），必须先发起 事前確認：说明原因、影响范围、替代方案，再经用户确认后修改。

# 定期停止与报告（每20分钟）
- 自动执行过程中，以 `${TIMESLICE_MINUTES}` 分钟为一个时间片：无论当前批次成功/失败，到点必须停止并输出一次报告。
- 报告内容（不省略）：
	- 已完成并 green 的用例范围（例：`#1-#5`）与冻结状态
	- 当前进行中的用例编号与失败概要（关键 errorCode/断言差异/异常堆栈摘要）
	- 本时间片内改动的测试文件清单（仅 `test/**`）
	- 本时间片最后一次执行的 Jest 命令与结果（通过/失败、耗时）
	- 下一步计划（下一个 5 个用例范围，或需要 事前確認 的点）
- 报告后必须等待用户确认（例如回复“继续”/“暂停”/“调整范围”）才能进入下一轮时间片。

# 生成前确认（事前確認）
- 如果仕様書的用语/取值与实现可能不一致，生成前必须先确认：
	- 仕様書の mediumケース数=${TOTAL_CASES}、ケース番号が `${CASE_RANGE}` の前提で連番になっていること（生成範囲の取り違え防止）
	- `procType`/`dataType` の列挙値（`src/util/Constants.ts`）
	- 対象API/リクエスト形式（openapi.json または controller/service）
	- エラーレスポンス形状（既存 medium テストの `errors.meta` 形式に合わせる）
	- DB 事後確認の対象テーブル/項目（`src/data/entity` と `test/medium` の既存パターン）

# 进度汇报（進捗）
- 每次输出前 1 句：说明“将读取/将生成/将对齐”的目标。

# 参照路径（従業員マスタ=WORKER・登録）

## 设计书（単体テスト仕様書）
- ${SPEC_PATH}

## 既存 medium テスト（书式参考）
- test/medium/importData/v1-postImportDataValidation-workerAdd.medium.ts
- test/medium/importData/v1-postImportData-workerAdd.medium.ts

## 生成目标（将由 agent 输出草稿，默认不落盘）
- ${OUT_TEST_VALIDATION}
- ${OUT_TEST_REGISTRATION}

## 实现参照（入口/取込分岐）
- src/service/ImportDataService.ts

## 关联实现（推移表生成/時給更新/契約書更新）
- src/service/ComponentUnitAmountCommonService.ts

## 参考（agent 運用例）
- ../../../.github/agents/调试单个jest case.agent.md