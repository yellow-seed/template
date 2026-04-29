# dotenvx による GH_TOKEN 管理計画

## 背景

`GH_TOKEN` を平文の環境変数や `.env` として扱うと、Codex や Claude Code などの AI エージェントがコマンド実行、ファイル読み取り、ログ出力を通じて値を参照できる可能性がある。

このリポジトリでは dotenvx で環境別ファイルを暗号化しつつ、PC(local) / PRD 用の復号鍵を AI エージェントのプロセスに持たせない構造を目指す。
一方で、AI エージェントが `gh` コマンドを使えなくなると PR / Issue / CI 確認などの作業に支障が出るため、Remote 用には AI エージェントが使ってよい GitHub CLI 認証 token だけを復号し、Remote 起動時に作業用 `.env` として生成する。

参考:

- [Managing Private Keys - Dotenvx](https://dotenvx.com/docs/learn/private-keys/introduction)
- [AIエージェントへの環境変数漏洩を防ぐ](https://zenn.dev/mun/articles/74ed03ca747f1d)

## 目的

- `GH_TOKEN` を dotenvx で環境別に暗号化して管理できるようにする
- `.env` 自体は Git 管理せず、各環境の起動時に生成される作業用ファイルにする
- 暗号化済み `.env.local` / `.env.remote` と `.env.sample` を Git 管理できる状態にする
- 復号鍵 `.env.*.keys` はリポジトリ内の `secrets/` に置きつつ、Git 管理とコンテナマウント対象から外す
- PC(local) / Remote(Web 版 Claude Code・Codex) / PRD の環境ごとに、配置するファイルと注入する環境変数を分ける
- Codex / Claude Code の AI エージェントプロセスには PC(local) 用の `DOTENV_PRIVATE_KEY*` を持たせない
- Remote(Web 版 Claude Code・Codex) では、AI 用 `.env.remote` の復号鍵だけを固定で注入し、起動セットアップで AI 用の値だけからなる `.env` を生成する
- AI エージェントが必要に応じて `gh` コマンドを利用できるように、AI 用の最小権限 `GH_TOKEN` を `.env.remote` で用意する
- 人間が明示的に実行するコマンドだけが dotenvx 経由で復号できるようにする

## 非目標

- AI エージェントに PC(local) / PRD 用の dotenvx 復号鍵を直接利用させること
- PC(local) / PRD 用の `.env.*.keys` を Remote 環境や devcontainer にファイルとして配置すること
- `.env.*.keys` や `DOTENV_PRIVATE_KEY*` を GitHub リポジトリに保存すること
- 現時点で不要な PRD 用 secrets を実運用として設計すること
- GitHub Actions 用の secrets 設計まで同時に確定すること

## 推奨構造

```text
template/
├── .env                       # 作業用。Git 管理しない。環境ごとに生成する
├── .env.sample                # サンプル。Git 管理する
├── .env.local                 # PC(local) 用 GH_TOKEN。dotenvx 暗号化済み。Git 管理する
├── .env.remote                # Remote AI 用 GH_TOKEN。dotenvx 暗号化済み。Git 管理する
├── .env.production            # PRD 用。現時点では作らない、または空/テンプレートのみ
├── .envrc                     # Host のみで鍵を export する場合に使う
├── secrets/
│   ├── .env.local.keys        # PC(local) 用復号鍵。Git 管理しない。コンテナにマウントしない
│   └── .env.remote.keys       # Remote AI 用復号鍵。Git 管理しない。Web 側 secret に登録する
├── compose.yml
├── .devcontainer/
│   └── devcontainer.json
└── scripts/
    ├── gh-setup.sh
    ├── setup-remote-env       # .env.remote から Remote 用 .env を生成する。gh-setupに統合可能
    └── gh-remote              # .env を source して gh を実行する薄いラッパー。gh-setupに統合可能
```

## 環境分類

| 環境                               | 用途                                       | 暗号化ファイル             | 復号鍵                         | AI 用 `GH_TOKEN`                |
| ---------------------------------- | ------------------------------------------ | -------------------------- | ------------------------------ | ------------------------------- |
| PC(local)                          | 人間の手元で初期設定、手動復号、検証を行う | `.env.local`               | `secrets/.env.local.keys` のみ | 必要なら local 用 `.env` を生成 |
| Remote(Web 版 Claude Code / Codex) | Web 版 AI エージェントが作業する           | `.env.remote`              | Web 側 secret に固定登録       | 起動時に AI 用 `.env` を生成    |
| PRD                                | 本番環境。現状 `GH_TOKEN` 用途は特にない   | 現時点では実体 secret 不要 | 配置しない                     | 注入しない                      |

PRD は現時点では `GH_TOKEN` を必要としないため、実際の secret や復号鍵は作らない。
将来 PRD で dotenvx 管理が必要になった場合だけ、PRD 専用の暗号化済みファイルを追加し、復号鍵は本番 secret manager 側で管理する。
この計画では、必要なら将来用の空ファイルやテンプレートだけを検討し、平文値や復号鍵は置かない。

## セキュリティ方針

### `.env`

- Git 管理しない
- Remote / PC(local) の起動セットアップで生成される作業用ファイルとして扱う
- Remote では AI エージェントが読める前提にする
- Remote の `.env` には AI 用の最小権限 `GH_TOKEN` だけを入れる
- `.env` を生成するだけでは shell の環境変数にはならないため、Remote では shell 起動時に source して使う

### `.env.sample`

- Git 管理する
- 必要な環境変数名だけを示し、実値や暗号化値は入れない
- Remote で生成される `.env` の項目をレビューしやすくするために使う

### `.env.local`

- dotenvx で暗号化した状態のみ Git 管理する
- PC(local) で人間が明示的に復号する `GH_TOKEN` を管理する
- PC(local) / Remote / PRD 用の値を混在させない
- 変更差分では暗号化値のみをレビュー対象にする

### `.env.remote`

- dotenvx で暗号化した状態のみ Git 管理する
- Remote(Web 版 Claude Code / Codex) が `gh` を使うための AI 用 `GH_TOKEN` だけを管理する
- Remote 起動セットアップで復号し、AI 用の値だけからなる `.env` を生成する
- PC(local) / PRD 用の秘密情報を含めない
- `GH_TOKEN` をローテーションする場合は、`.env.remote` の暗号化値を更新する
- Claude Code on the web / Codex on the web 側の secret は、`GH_TOKEN` 実値ではなく `.env.remote` の復号鍵を固定で登録する

### `.env.*.keys`

- PC(local) 用は `secrets/.env.local.keys` に置く
- Remote AI 用は `secrets/.env.remote.keys` に置き、Web 側 secret / environment variable にはこの中の Remote 用復号鍵だけを登録する
- Git 管理しない
- devcontainer / Docker / Remote workspace / PRD にファイルとしてマウントしない
- PC(local) 用の `secrets/.env.local.keys` は、必要なときだけ人間のシェルで読み込む
- `secrets/` はリポジトリ内に存在してよいが、コンテナの bind mount / workspace mount からは明示的に除外する

### AI エージェント

- AI エージェントに渡す環境変数は、用途ごとに分類して扱う
- PC(local) / PRD 用の `DOTENV_PRIVATE_KEY*` は、AI エージェントが読む必要のない環境変数として扱い、起動環境へ注入しない
- Remote では `GH_TOKEN` の実値を Web 側 secret に直接設定せず、AI 用 `.env.remote` を復号するための専用鍵だけを固定で注入する
- Remote の起動セットアップは `.env.remote` から AI 用の最小権限 `GH_TOKEN` だけを復号し、Git 管理されない `.env` を生成する
- Remote の AI エージェントは、生成済み `.env` を source した shell で `gh` を実行する
- Web 版 / Remote 実行ではローカルのラッパーが必ず効くとは限らないため、ラッパーによる unset を主要な防御策にしない
- ローカル CLI でラッパーを使える場合は、復号鍵を落とす補助的な防御策として利用してよい

### GitHub CLI 認証

- 人間が dotenvx で復号する `GH_TOKEN` は、初期設定や手動操作で使う
- Remote(Web 版 Claude Code / Codex) では、AI 用に権限を絞った別の Fine-grained PAT を `.env.remote` に暗号化して保存する
- PC(local) で AI エージェントが `gh` を使う場合も、同じく AI 用 `GH_TOKEN` の明示注入を基本にする
- PRD には現時点で `GH_TOKEN` を渡さない
- AI 用の `GH_TOKEN` は dotenvx の本番用 `GH_TOKEN` と同一にしない
- AI 用の `GH_TOKEN` は、対象 repo と必要な操作に絞った権限だけを付与する
- AI 用の `GH_TOKEN` を復号できる Remote 専用鍵を渡しても、PC(local) / PRD 用の `DOTENV_PRIVATE_KEY*` は渡さない
- Remote では最終的に `GH_TOKEN` が作業用 `.env` と shell 環境に現れる前提で扱う

### Remote 用 `GH_TOKEN` の権限

Remote(Web 版 Claude Code / Codex) 用 Fine-grained PAT は、対象 repository を必要な repo のみに絞り、次の repository permissions を付与する。

| 権限              | Access | 用途                                              |
| ----------------- | ------ | ------------------------------------------------- |
| Contents          | Write  | branch 作成、commit push、通常ファイルの変更      |
| Pull requests     | Write  | PR 作成、PR 更新、レビューコメント対応            |
| Issues            | Write  | Issue 作成、Issue コメント、ラベル操作            |
| Discussions       | Write  | Discussion 作成                                   |
| Actions           | Read   | GitHub Actions の run / job / log / artifact 参照 |
| Commit statuses   | Read   | commit status / status check の参照               |
| Dependabot alerts | Read   | Dependabot alert の参照                           |
| Workflows         | Write  | `.github/workflows/` 配下の CI 設定修正           |
| Metadata          | Read   | repo metadata 参照。Fine-grained PAT で必須扱い   |

追加で、次の権限は原則付与しない。

- Administration
- Secrets / Variables / Environments
- Dependabot secrets
- Deployments
- Webhooks
- Repository security advisories
- Secret scanning alerts

CI の修正では `.github/workflows/` 配下を変更して push する必要があるため、`Workflows: Write` はデフォルトで付与する。
ただし、workflow file の変更は影響が大きいため、PR レビューで差分を必ず確認する。

Dependabot の「参照」は `Dependabot alerts: Read` に限定する。
Dependabot secrets の一覧や更新はこの用途に含めない。

Discussion 作成は GitHub Discussions が対象 repository で有効になっていることを前提にする。
Fine-grained PAT の設定画面で `Discussions` permission が利用できない場合は、Discussion 作成だけを Remote AI の対象外にするか、別の認証方式を検討する。

## 想定フロー

### PC(local) 初期セットアップ

```bash
dotenvx set GH_TOKEN "実際のトークン" -f .env.local
mkdir -p secrets
mv .env.keys secrets/.env.local.keys
```

`GH_TOKEN` の実値はチャットやログに貼らず、ユーザーのローカルシェルで入力する。
dotenvx が生成する `.env.keys` は、用途に応じて `secrets/.env.local.keys` または `secrets/.env.remote.keys` に移動する。

### 人間が復号してコマンドを実行する

```bash
export $(grep '^DOTENV_PRIVATE_KEY' secrets/.env.local.keys)
dotenvx run -f .env.local -- gh auth status
```

このフローは、人間が明示的に実行するコマンドに限定する。

### Remote AI 用 token を更新する

AI 用 Fine-grained PAT を作成またはローテーションしたら、PC(local) で `.env.remote` の暗号化値を更新する。

```bash
dotenvx set GH_TOKEN "AI用のFine-grained PAT" -f .env.remote
mkdir -p secrets
mv .env.keys secrets/.env.remote.keys
```

`secrets/.env.remote.keys` の中にある `.env.remote` 用の復号鍵だけを、Claude Code on the web / Codex on the web の secret / environment variable 設定へ登録する。
以後、AI 用 `GH_TOKEN` の実値を変更するときは `.env.remote` を更新して commit / push する。
Web 側 secret は、`.env.remote` 用の復号鍵を作り直した場合だけ更新する。

### Remote(Web 版 Claude Code / Codex) を用意する

Remote 環境には Git 管理された `.env.sample` と、暗号化済み `.env.remote` が存在する。
`secrets/.env.local.keys` は配置せず、PC(local) 用の `DOTENV_PRIVATE_KEY*` も環境変数として注入しない。

`.env.remote` には AI 用の最小権限 `GH_TOKEN` だけを入れる。

Claude Code on the web / Codex on the web の secret / environment variable 設定には、`GH_TOKEN` の実値ではなく `.env.remote` の復号鍵を固定で登録する。
この復号鍵は、PC(local) 用 `.env.local` や PRD 用 secret を復号できないものにする。

`GH_TOKEN` をローテーションする場合は、PC(local) で `.env.remote` の暗号化値を更新して commit / push する。
Web 側の secret 設定は変更しない。
これにより、Claude Code on the web と Codex on the web の設定変更なしに、リポジトリ側の暗号化値更新へ追随できる。

Remote では AI エージェントが `.env.remote` の復号鍵を参照可能である前提で設計する。
この鍵で復号できる内容は、AI 用 `GH_TOKEN` だけに限定する。

`.env.remote` は、ファイルが存在するだけでは Remote の標準環境変数にならない。
そのため、Remote 起動セットアップで次を行う。

```bash
bash scripts/env-setup.sh
```

`scripts/env-setup.sh` は、`.env.remote` を復号して AI 用の値だけからなる Git 管理されない `.env` を生成する。
実装は次の方針にする。

```bash
dotenvx run -f .env.remote -- sh -c 'umask 077; printf "GH_TOKEN=%s\n" "$GH_TOKEN" > .env'
chmod 600 .env
```

`.env` を生成するだけでは、既存 shell の環境変数にはならない。
Remote では次のどちらかを採用する。

- Remote の shell 初期化で `.env` を `set -a; . ./.env; set +a` する
- `gh` 実行前に `set -a; . ./.env; set +a` してから呼び出す

`gh` 直実行を自然に使いたい場合は、Remote shell の初期化で `.env` を source する。

守る境界は、`GH_TOKEN` を完全に隠すことではなく、次の 2 点に置く。

- PC(local) / PRD 用の `DOTENV_PRIVATE_KEY*` と `secrets/.env.local.keys` は Remote に存在させない
- `.env.remote` で管理する `GH_TOKEN` は AI 用に分離し、対象 repo、権限、有効期限を最小化する

AI 用 `GH_TOKEN` は、`.env.remote` の更新によって定期的にローテーションする。
権限を広げる必要が出た場合は既存 token を使い回さず、新しい用途に合わせて見直す。

### PRD を用意する

現時点では PRD で `GH_TOKEN` を使う必要はないため、PRD には `.env.*.keys` も `GH_TOKEN` も置かない。
ファイルだけ用意する場合は、実値を含まないテンプレートまたは暗号化済みの空ファイルに留める。

将来 PRD 用の環境変数が必要になった場合は、PC(local) / Remote とは別の PRD 専用ファイルと復号鍵を作り、復号鍵はリポジトリではなく本番 secret manager に保存する。

### AI エージェント環境変数を整理する

AI エージェントの起動経路ごとに、注入する環境変数を明示する。

| 分類                     | 例                                           | 方針                                        |
| ------------------------ | -------------------------------------------- | ------------------------------------------- |
| PC(local) / PRD 用復号鍵 | `DOTENV_PRIVATE_KEY`, `DOTENV_PRIVATE_KEY_*` | AI エージェントへ注入しない                 |
| Remote AI 用復号鍵       | `.env.remote` 用の `DOTENV_PRIVATE_KEY_*`    | Web 側 secret に固定登録する                |
| CLI 認証                 | `GH_TOKEN`                                   | Remote 起動時に生成した `.env` から利用する |
| 通常の開発用設定         | `NODE_ENV`, `CI`, `DEBUG` など               | 必要性と露出リスクを個別に判断する          |

Web 版 / Remote 実行では、ローカルの `PATH` やラッパースクリプトを通らない可能性がある。
そのため、PC(local) / PRD 用の復号鍵は「起動後に消す」のではなく「最初から渡さない」ことを基本方針にする。

ローカル CLI では、追加の安全策としてラッパーを使って `DOTENV_PRIVATE_KEY*` を unset してもよい。
ただし、そのラッパーに依存した設計にはしない。

Remote の起動セットアップで `.env.remote` を復号するため、Remote には dotenvx CLI が必要になる。
Remote 環境に dotenvx が入っていない場合は、セットアップ手順でインストールするか、`npx @dotenvx/dotenvx run -f .env.remote -- ...` のように実行する。

### AI エージェントに `gh` を使わせる

AI エージェントが `gh` を使えるように、Remote 起動セットアップでは `.env.remote` から AI 用の最小権限 Fine-grained PAT を `GH_TOKEN` として復号し、作業用 `.env` に書き出す。
Host 側の `gh auth login` 状態や GitHub App / MCP などの別経路には依存しない。

このときも、`secrets/.env.local.keys` と PC(local) / PRD 用の `DOTENV_PRIVATE_KEY*` は AI エージェントから見えない状態を維持する。
`.env.remote` で復号する `GH_TOKEN` は、PC(local) 用 `.env.local` の token ではなく、AI 作業に必要な repo / 権限だけに絞った token を使う。

## 実装タスク

1. `.gitignore` を調整する
   - `.env`
   - `.env.keys`
   - `.env.*.keys`
   - `secrets/`
   - 暗号化済み `.env.local` / `.env.remote` と `.env.sample` は Git 管理する

2. ドキュメントを追加する
   - dotenvx による `GH_TOKEN` 追加手順
   - `.env.local.keys` を `secrets/` へ移動する手順
   - Remote 用 `.env.remote` と `secrets/.env.remote.keys` の作成手順
   - Remote 起動セットアップで `.env.remote` から作業用 `.env` を生成する手順
   - `GH_TOKEN` ローテーション時は `.env.remote` だけを更新し、Web 側 secret は原則更新しない運用
   - PC(local) / Remote / PRD の環境分類
   - 人間が `.env.local` を `dotenvx run` で復号する手順
   - AI エージェントには復号鍵を持たせない注意点
   - AI エージェントが `gh` を使うための認証方針

3. AI エージェント向けの環境変数ポリシーを追加する
   - AI エージェントへ渡してよい環境変数と渡さない環境変数を分類する
   - PC(local) / PRD 用の `DOTENV_PRIVATE_KEY*` は Web 版 / Remote 実行を含めて注入しない
   - Remote では `.env.remote` 用の復号鍵だけを固定で注入する
   - Remote では AI 用の最小権限 `GH_TOKEN` を `.env.remote` から復号して Git 管理されない `.env` を生成する
   - Remote shell で `.env` を source する（`set -a; . ./.env; set +a`）
   - Remote の起動セットアップは `scripts/env-setup.sh` で行う
   - ローカル CLI 用ラッパーは補助策として扱い、主要な前提にしない

4. Remote / devcontainer / Docker を使う場合の方針を追記する
   - `secrets/` はリポジトリ内に置くがマウントしない
   - 鍵ファイルはコンテナへコピーしない
   - `containerEnv` を使う場合も PC(local) / PRD 用の `DOTENV_PRIVATE_KEY*` は渡さない
   - Web 側 secret には `.env.remote` 用の復号鍵だけを登録する
   - Remote で dotenvx CLI を利用できるようにする
   - Remote の AI 用 `GH_TOKEN` は復号可能である前提で、権限と有効期限を最小化する
   - Remote 用 Fine-grained PAT の repository permissions を明記する

5. PRD の方針を追記する
   - 現時点では `GH_TOKEN` も `.env.*.keys` も置かない
   - ファイルだけ用意する場合は、実値を含まないテンプレートまたは暗号化済みの空ファイルに留める
   - 将来必要になった場合は PRD 専用の dotenvx ファイルと secret manager 管理に分離する

6. 検証手順を追加する
   - `dotenvx run -f .env.local -- gh auth status` が人間のシェルで通ること
   - Remote 起動セットアップ後に AI 用の値だけを含む `.env` が生成されること
   - AI エージェント起動後に PC(local) / PRD 用の `DOTENV_PRIVATE_KEY*` が見えないこと
   - AI エージェント起動後に必要な `gh` コマンドが実行できること
   - Web 版 / Remote 実行では、`.env.remote` 用の復号鍵だけが注入され、PC(local) / PRD 用の復号鍵が含まれないこと
   - PRD に `GH_TOKEN` と `DOTENV_PRIVATE_KEY*` が存在しないこと
   - `.env` / `.env.local.keys` / `.env.remote.keys` が Git 管理対象外であること

## 検証コマンド案

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
grep '^GH_TOKEN=' .env
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

AI エージェント内では、PC(local) / PRD 用の復号鍵が何も表示されない状態を期待する。
Remote では、起動セットアップ後に AI 用 `GH_TOKEN` だけを含む `.env` が生成される状態を期待する。
Remote では、`.env` を source した AI 用 `GH_TOKEN` によって `gh auth status` が成功する状態を期待する。
`.env` を source した状態で `gh auth status` が成功することを期待する。
PRD では、現時点では `GH_TOKEN` も復号鍵も表示されない状態を期待する。

ローカル CLI の補助確認:

```bash
env | grep '^DOTENV_PRIVATE_KEY' || true
gh auth status
```

## リスクと対策

| リスク                                                          | 対策                                                                                                |
| --------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `.env` / `.env.*.keys` を誤って commit する                     | `.gitignore` と `git check-ignore` で防ぐ                                                           |
| `secrets/` がコンテナへマウントされる                           | compose / devcontainer 設定でマウント対象から除外する                                               |
| AI プロセスが PC(local) / PRD 用の `DOTENV_PRIVATE_KEY*` を読む | 起動環境へ注入しない。ローカル CLI ではラッパーも補助的に使う                                       |
| AI プロセスが本番用 `GH_TOKEN` を読む                           | 本番用 token とは別の AI 用最小権限 token を使う                                                    |
| AI プロセスが `gh` を使えなくなる                               | `bash scripts/env-setup.sh` で `.env` を生成し、shell 初期化で source する                          |
| `.env` が生成されただけで shell に反映されない                  | shell 初期化で `set -a; . ./.env; set +a` を実行する                                                |
| Remote に dotenvx CLI がない                                    | 起動セットアップでインストールするか、`npx @dotenvx/dotenvx` 経由で実行する                         |
| `.env.remote` 用復号鍵が Remote に常時置かれる                  | 復号対象を AI 用 `GH_TOKEN` だけに限定し、repo、権限、有効期限、ローテーションで制限する            |
| `GH_TOKEN` ローテーション時に Web 側設定更新が必要になる        | Web 側には `.env.remote` 用復号鍵だけを固定登録し、token 実値は `.env.remote` 更新で追随させる      |
| AI 用 token の権限が広がりすぎる                                | 推奨 permissions から始め、必要が出た権限だけ追加する                                               |
| workflow file を誤って変更できる                                | `Workflows: Write` は CI 修正のため許可し、PR レビューで workflow 差分を確認する                    |
| Web 版でローカルラッパーが効かない                              | ラッパー前提にせず、環境変数の注入元で復号鍵を除外する                                              |
| Remote 環境に PC(local) 用鍵を置きっぱなしにする                | `secrets/.env.local.keys` を Remote / devcontainer へコピーしない                                   |
| PRD に不要な GitHub token が残る                                | 現時点では PRD に `GH_TOKEN` を注入しない                                                           |
| PRD 用ファイルに平文や復号鍵が入る                              | テンプレートまたは暗号化済み空ファイルに留め、鍵は置かない                                          |
| `GH_TOKEN` の権限が広すぎる                                     | Fine-grained PAT を使い、repo と権限を最小化する                                                    |

## 完了条件

- `GH_TOKEN` を dotenvx の暗号化済み `.env.local` で管理できる
- `.env` が Git 管理対象外である
- `.env.local.keys` が `secrets/` 配下で管理され、Git 管理対象外である
- `.env.remote` で AI 用 `GH_TOKEN` を暗号化管理できる
- `secrets/.env.remote.keys` が Git 管理対象外である
- `secrets/` がコンテナへマウントされない
- PC(local) / Remote / PRD ごとのファイル配置と環境変数注入方針が明確である
- `.env.local.keys` / `.env.remote.keys` と `DOTENV_PRIVATE_KEY*` が Git 管理対象外である
- 人間は `dotenvx run` 経由で必要な GitHub CLI 操作を実行できる
- Codex / Claude Code の AI プロセスから PC(local) / PRD 用の復号鍵が見えない
- Codex / Claude Code on the web は、Web 側 secret を変えずに `.env.remote` 更新後の AI 用 `GH_TOKEN` を利用できる
- Remote 起動セットアップで AI 用の値だけを含む `.env` を生成できる
- Remote では shell 初期化で `.env` を source して `gh` を実行できる
- Codex / Claude Code の AI プロセスから、必要な範囲で `gh` コマンドを実行できる
- PRD には現時点で不要な `GH_TOKEN` と復号鍵が存在しない
