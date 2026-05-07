---
name: template-sync
description: "テンプレート同期スキル。yellow-seed/template と派生リポジトリ間の変更のやりとりを支援（Pull: テンプレート→子へ反映、Push: 子で得た改善をテンプレートへ還流）。Use when: テンプレート更新の反映、派生→template へのフィードバック、template 同期全般。"
---

# テンプレート同期

`yellow-seed/template` と**派生リポジトリ**のあいだで差分を運ぶ。向きに応じて参照ドキュメントを開く。パス列挙より**役割・パターン**で考える（表・原則は共通参照に集約）。

## 同期の向き

| 向き | ソース | 宛先 | 参照 |
|------|--------|------|------|
| **Pull** | `yellow-seed/template`（既定 `main`） | 派生リポジトリ | [references/pull.md](references/pull.md) |
| **Push** | 派生で検証済みの、テンプレに載せられる変更 | `yellow-seed/template` | [references/push.md](references/push.md) |

Push は派生の全マージではなく、**一般化でき秘密・固有情報がない差分**に限る。

## 共通参照

パターン別の同期方針・同期タイプ早見・調査コマンド・トラブルシュート・他スキル連携・`TEMPLATE_REPO` は [references/shared.md](references/shared.md)。

**読み順の例**: `shared` で対象と原則を把握 → Pull なら `pull`、Push なら `push` の手順へ進む。
