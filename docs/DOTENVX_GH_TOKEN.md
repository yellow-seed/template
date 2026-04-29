# dotenvx による Remote AI 用 GH_TOKEN 管理

このドキュメントは、Remote(Web 版 Claude Code / Codex) で AI エージェントに GitHub CLI を使わせるための `GH_TOKEN` 運用を記録します。
汎用的な dotenvx 環境変数の追加・変更手順は [.github/skills/dotenvx-env/SKILL.md](../.github/skills/dotenvx-env/SKILL.md) を参照してください。

`GH_TOKEN` は Remote AI に必要な場合だけ扱い、PC(local) 用 token や本番用 token と混在させません。
作業用の `.env` は Git 管理せず、Remote の起動時に生成します。

## 管理するファイル

| ファイル                   | 用途                                               | Git 管理 |
| -------------------------- | -------------------------------------------------- | -------- |
| `.env.sample`              | 必要な環境変数名のサンプル                         | する     |
| `.env`                     | 起動時に生成する作業用ファイル                     | しない   |
| `.env.local`               | PC(local) で人間が使う `GH_TOKEN` の暗号化ファイル | する     |
| `.env.remote`              | Remote AI 用 `GH_TOKEN` の暗号化ファイル           | する     |
| `secrets/.env.local.keys`  | PC(local) 用復号鍵                                 | しない   |
| `secrets/.env.remote.keys` | Remote AI 用復号鍵                                 | しない   |

`secrets/` はリポジトリ内に置けますが、devcontainer / Docker / Remote workspace へコピーまたはマウントしません。

## PC(local) で Remote AI 用 token を作成する

`GH_TOKEN` の実値はチャット、Issue、ログに貼らず、人間のローカルシェルで入力してください。
Remote AI 用には、AI 用に権限を絞った別の Fine-grained PAT を使います。
PC(local) 用 token や本番用 token と同じ値にしないでください。

```bash
VAR_NAME=GH_TOKEN
read -rsp "$VAR_NAME: " SECRET_VALUE; echo
dotenvx set -f .env.remote "$VAR_NAME" "$SECRET_VALUE"
unset SECRET_VALUE
mkdir -p secrets
mv .env.keys secrets/.env.remote.keys
chmod 600 secrets/.env.remote.keys
```

Claude Code on the web / Codex on the web 側の secret / environment variable には、`GH_TOKEN` の実値ではなく `.env.remote` 用の `DOTENV_PRIVATE_KEY*` だけを登録します。
`GH_TOKEN` をローテーションするときは `.env.remote` の暗号化値を更新して commit / push します。
`.env.remote` 用の復号鍵を作り直さない限り、Web 側 secret は原則更新しません。

## PC(local) 用 token について

人間が PC(local) で GitHub CLI を使う token が必要な場合は、Remote AI 用とは別に `.env.local` で管理します。
この token は AI エージェントへ渡しません。

```bash
VAR_NAME=GH_TOKEN
read -rsp "$VAR_NAME: " SECRET_VALUE; echo
dotenvx set -f .env.local "$VAR_NAME" "$SECRET_VALUE"
unset SECRET_VALUE
mkdir -p secrets
mv .env.keys secrets/.env.local.keys
chmod 600 secrets/.env.local.keys
```

人間が明示的に GitHub CLI を使う場合だけ、PC(local) 用の復号鍵を読み込みます。

```bash
set -a
. secrets/.env.local.keys
set +a
dotenvx run -f .env.local -- gh auth status
```

## Remote 起動時に .env を生成する

Remote には dotenvx CLI が必要です。未導入の場合は `bash scripts/installers/dotenvx.sh` などで用意してください。

```bash
bash scripts/env-setup.sh
```

このスクリプトは `.env.remote` を復号し、Git 管理されない `.env` に `GH_TOKEN` だけを書き出します。
生成した `.env` は `0600` 相当の権限になります。

`.env` を生成するだけでは既存 shell の環境変数にはならないため、次のどちらかで `gh` を実行します。

```bash
set -a; . ./.env; set +a
gh auth status
```

または Remote shell の初期化で次を実行します。

```bash
set -a
. ./.env
set +a
```

## AI エージェント向け環境変数ポリシー

| 分類                     | 例                                           | 方針                                        |
| ------------------------ | -------------------------------------------- | ------------------------------------------- |
| PC(local) / PRD 用復号鍵 | `DOTENV_PRIVATE_KEY`, `DOTENV_PRIVATE_KEY_*` | AI エージェントへ注入しない                 |
| Remote AI 用復号鍵       | `.env.remote` 用の `DOTENV_PRIVATE_KEY_*`    | Web 側 secret に固定登録する                |
| CLI 認証                 | `GH_TOKEN`                                   | Remote 起動時に生成した `.env` から利用する |
| 通常の開発用設定         | `NODE_ENV`, `CI`, `DEBUG` など               | 必要性と露出リスクを個別に判断する          |

Web 版 / Remote 実行ではローカルの `PATH` 制御に依存できないため、PC(local) / PRD 用の復号鍵は最初から注入しないでください。

## Remote 用 Fine-grained PAT の推奨権限

対象 repository を必要最小限に絞り、次の repository permissions から始めます。

| 権限              | Access | 用途                                         |
| ----------------- | ------ | -------------------------------------------- |
| Contents          | Write  | branch 作成、commit push、通常ファイルの変更 |
| Issues            | Write  | Issue 作成、Issue コメント、ラベル操作       |
| Discussions       | Write  | Discussion 作成                              |
| Actions           | Read   | GitHub Actions の run / job / log 参照       |
| Artifact metadata | Read   | Actions アーティファクトのメタデータ参照     |
| Commit statuses   | Read   | commit status / status check の参照          |
| Workflows         | Write  | `.github/workflows/` 配下の CI 設定修正      |
| Metadata          | Read   | repo metadata 参照                           |
| Agent tasks       | Read   | エージェントタスクの参照                     |

原則として、Administration、Secrets / Variables / Environments、Dependabot secrets、Deployments、Webhooks、Repository security advisories、Secret scanning alerts は付与しません。

## PRD の方針

現時点では PRD に `GH_TOKEN` も `.env.*.keys` も置きません。
将来必要になった場合は PC(local) / Remote とは別の PRD 専用 dotenvx ファイルを作り、復号鍵は本番 secret manager で管理します。

## 検証

PC(local):

```bash
git check-ignore .env
git check-ignore .env.keys
git check-ignore secrets/.env.local.keys
git check-ignore secrets/.env.remote.keys
dotenvx run -f .env.local -- gh auth status
```

Remote(Web 版 Claude Code / Codex):

```bash
env | cut -d= -f1 | grep '^DOTENV_PRIVATE_KEY' || true
bash scripts/env-setup.sh
test -f .env
grep -q '^GH_TOKEN=' .env
set -a; . ./.env; set +a
gh auth status
```

PRD:

```bash
env | grep '^DOTENV_PRIVATE_KEY' || true
env | grep '^GH_TOKEN=' || true
test ! -f secrets/.env.local.keys
test ! -f secrets/.env.remote.keys
```
