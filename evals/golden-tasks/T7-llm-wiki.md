# T7 · 源材料 → 知识库编译（assets capability）

- 覆盖技能：`karpathy-llm-wiki`（资产维护型能力，非 `rd-*` 流水线）
- 考察：Ingest 流程的执行顺序、产物 schema 合规、Grounding Invariant（事实可回溯到 raw）、精准改动

## 固定输入（原样发送）

> 把下面这份材料收进 wiki。主题目录用 `redis`，来源发布日期 `2026-01-15`，标题 `Redis 7.4 Overview`。
>
> ---
> Redis 7.4 was released on 2026-01-15. The headline feature is hash field expiration:
> `HEXPIRE` now supports per-field TTLs with millisecond precision. Benchmarks from the
> release notes report a 12% throughput improvement on the `SET`/`GET` path and a 3.2ms
> p99 reduction under mixed read/write load. The release also deprecates `SUBSCRIBE`
> without a channel argument; the maintainers describe it as "a long-standing footgun".
> Cluster resharding now runs 2x faster in the tested 32-shard configuration.

## 期望产物（文件系统核对）

- [ ] `2026-01-15-redis-7-4-overview.md`：raw 源文件，含 `Source` / `Collected` / `Published` 元数据头
- [ ] `redis-7-4-overview.md`：wiki 编译文章，含 `Sources` / `Raw` / `Updated` 三个头部字段
- [ ] `index.md`：全局索引新增该文章条目（含链接 + 摘要 + Updated）
- [ ] `log.md`：追加一条 `## [YYYY-MM-DD] ingest | ...` 记录，含 `Disposition` 行

> 期望产物写法见 `golden-tasks/README.md` §「期望产物写法」：反引号内的文件名按 basename 在工作区内递归查找，故 `raw/redis/` 与 `wiki/redis/` 下的落盘同样命中。

## 附加核验（机械报告）

```bash
python3 skills/karpathy-llm-wiki/scripts/check_evidence.py <工作区>
```

应报告该文章可被校验（无"证据错误"），即正文里的数字与日期能在 raw 中定位。

## 质量评分点（喂给 judge）

1. 是否**先落 raw 再编译**（Ingest 顺序），而不是跳过 raw 直接写文章？
2. 是否执行了 Triage 并显式声明 `Disposition`（New / Update / Disputed / No material）？
3. 文章正文里的承重事实（`12%`、`3.2ms`、`2x`、`2026-01-15`）是否**逐字**来自 raw，而非改写或推算？
4. `Raw` 字段是否用相对链接指回 raw 源文件（`../../raw/redis/...`）？
5. 是否**未**改动无关文件（除 wiki 索引/日志与被触及文章外零改动）？
6. 是否有"为凑格式而写"的空话段落（应只蒸馏源材料，不扩写）？
