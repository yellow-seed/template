# Codex / Claude Cloud Setup Stability Plan

## 背景

現在、Codex cloud の Environment Setup script に次を設定している。

```bash
bash .codex/hooks/codex-setup.sh
```

この実行が timeout している。一方で、軽量な `./.claude/hooks/gh-setup.sh` は動作する。

現行の `.codex/hooks/codex-setup.sh` は次の処理を一括実行する。

- remote session での `origin` 削除
- `.codex/hooks/env-setup.sh`
- `.codex/hooks/gh-setup.sh`
- skills directory setup
- git hooks setup

このうち `.codex/hooks/env-setup.sh` は `scripts/env-setup.sh` を経由し、さらに
`scripts/install-tools.sh` から `mise install` を実行する。timeout の主因はこの tool install phase と考える。

また、`dotenvx` を `mise install` の管理下に置いていることも問題。
Remote では `dotenvx` は通常の開発ツールではなく、`.env.remote` を復号して `GH_TOKEN` を用意するための bootstrap tool である。
`dotenvx` が使えないと `gh` 認証もできないため、`qlty` や `terraform` などの任意ツールと同じ重要度で扱わない。

`dotenvx` と GitHub 公式 CLI の `gh` はどちらも cURL で bootstrap できる。
Cloud setup の前提を単純にするため、Cloud core tool は npm / mise / OS package manager に分散させず、cURL で `~/.local/bin` に入れる方針にする。
ただし、`dotenvx` の install を `gh-setup.sh` に混ぜない。
`dotenvx`、`gh`、remote env 生成、gh extensions setup はそれぞれ別 script に分け、Cloud setup はそれらを順番に呼ぶだけにする。

## Codex cloud の前提

Codex cloud では、setup script と agent phase の責務が分かれる。

- Environment variables は Codex Environment settings で指定し、setup script と agent phase の両方で使える
- Secrets も Codex Environment settings で指定するが、setup script にだけ渡され、agent phase の前に削除される
- setup script は agent phase とは別 Bash session で実行されるため、script 内の `export` は後続の agent terminal に残らない
- agent phase に残したい環境変数は、Codex Environment settings の environment variables に置く
- setup で生成した PATH など shell 初期化が必要な値だけ、必要に応じて `~/.bashrc` に追記する

参考: <https://developers.openai.com/codex/cloud/environments>

## Web 画面で設定する内容

Codex の Web 画面では、対象 repository の Environment settings に以下を設定する。
repository 側の script には、これらの値を直書きしない。

重要: Web 側の Setup script / Maintenance script には、長い手順を直書きしない。
Web 側は repository 内の entrypoint を1つ呼ぶだけにし、手順の並びやファイル名の変更は repository 側で吸収する。
いま timeout している根本原因は、現行の `codex-setup.sh` が profile 分岐を持っておらず、必ず `env-setup` から `mise install` まで実行すること。
そのため、`codex-setup.sh` を軽量 profile 対応に直してから Web 側の entrypoint として使う。

### 1. Setup script

Environment Setup script には、Codex 用 entrypoint だけを指定する。
実際の手順は `.codex/hooks/codex-setup.sh` の default profile に閉じ込める。
default は timeout 回避を優先した軽量な cloud setup とする。

```bash
bash .codex/hooks/codex-setup.sh
```

default profile で行うこと:

- Codex remote session では `origin` を外す
- `scripts/bootstrap-dotenvx.sh` で `dotenvx` を cURL bootstrap する
- `scripts/bootstrap-gh.sh` で `gh` を cURL bootstrap する
- `.env.remote` から AI 用 `GH_TOKEN` だけを `.env` に生成する
- `scripts/setup-remote-env.sh` が `.env` を source し、agent phase 用に `~/.bashrc` も整える
- `gh` を用意したうえで `.codex/hooks/gh-setup.sh` を実行する
- skills directory を同期する
- git hooks を設定する

default profile で行わないこと:

- `bash .codex/hooks/env-setup.sh`
- `bash scripts/env-setup.sh`
- `bash scripts/install-tools.sh`
- `mise install`

`dotenvx` と `gh` の bootstrap は full toolchain の `mise install` とは分けて扱う。
`DOTENV_PRIVATE_KEY_REMOTE` 自体は agent phase に残さず、agent phase では `.env` に書き出した AI 用 `GH_TOKEN` だけを使う。
`gh-setup.sh` は `dotenvx` を install しない。`gh-setup.sh` は、用意済みの `gh` と `GH_TOKEN` を前提に gh extensions setup だけを行う。

### 2. Maintenance script

Maintenance script には、cached container 再開時に実行する軽い setup を指定する。

```bash
CODEX_SETUP_PROFILE=session bash .codex/hooks/codex-setup.sh
```

`session` profile では、`gh` がなければ bootstrap し、`setup-remote-env.sh` で生成済み `.env` の source と `~/.bashrc` の source 設定を維持する。
`.env` がない場合に復号し直す処理も、`setup-remote-env.sh` の責務にする。

### 3. Environment variables

Environment variables には、setup script と agent phase の両方で見えてよい値を指定する。

```text
CODEX_REMOTE=true
```

各値の意味:

| Name           | Value  | 用途                                           |
| -------------- | ------ | ---------------------------------------------- |
| `CODEX_REMOTE` | `true` | Codex cloud 実行であることを script 側に伝える |

`CODEX_SETUP_PROFILE` は Web 側の command inline で指定する。
Environment variables には置かない。

### 4. Secrets

Secrets には、setup script 中だけ使い、agent phase には残したくない値を指定する。

```text
DOTENV_PRIVATE_KEY_REMOTE=<.env.remote 用の復号鍵>
```

`DOTENV_PRIVATE_KEY_REMOTE` は `.env.remote` を復号して、Git 管理されない `.env` を生成するために使う。
Codex cloud の secret は setup script 後に削除されるため、agent phase では見えない想定にする。
上記の暫定 Setup script では `env-setup` 全体は呼ばないが、`.env.remote` の復号だけを先に行う。
これにより、`gh-setup.sh` は `GH_TOKEN` を持った状態で実行できる。

### 5. 設定しないもの

次の値は Web 画面に直接設定しない。

| 値         | 理由                                                                 |
| ---------- | -------------------------------------------------------------------- |
| `GH_TOKEN` | 実値を Web secret / environment variable に直接置かず、`.env.remote` で暗号化管理する |
| PC(local) 用の `DOTENV_PRIVATE_KEY*` | AI agent に渡さない。Remote 用の復号鍵だけを secret に登録する |
| PRD 用 secret | Codex cloud の開発作業用 environment には置かない                   |

## Web 画面設定の完成形

timeout 回避を優先する現在の完成形は次の状態にする。

| 設定欄                | 指定内容                                                                 |
| --------------------- | ------------------------------------------------------------------------ |
| Setup script          | `bash .codex/hooks/codex-setup.sh`                                       |
| Maintenance script    | `CODEX_SETUP_PROFILE=session bash .codex/hooks/codex-setup.sh`           |
| Environment variables | `CODEX_REMOTE=true`                                                      |
| Secrets               | `DOTENV_PRIVATE_KEY_REMOTE=<.env.remote 用の復号鍵>`                     |

この設定により、初回 setup でも `mise install` を実行せず、timeout の主因を避ける。
同時に、`.env.remote` から `GH_TOKEN` を生成してから `gh-setup.sh` を実行するため、gh setup も意味を持つ。
full tool install は、script 側を軽量化してから段階的に戻す。

## 将来の full setup 設定

Cloud setup の timeout が解消し、`full` profile の tool install が安定した後だけ、Setup script を次に変更できる。

| 設定欄                | 指定内容                                                   |
| --------------------- | ---------------------------------------------------------- |
| Setup script          | `CODEX_SETUP_PROFILE=full bash .codex/hooks/codex-setup.sh` |
| Maintenance script    | `CODEX_SETUP_PROFILE=session bash .codex/hooks/codex-setup.sh` |
| Environment variables | `CODEX_REMOTE=true`                                       |
| Secrets               | `DOTENV_PRIVATE_KEY_REMOTE=<.env.remote 用の復号鍵>`       |

この設定に変更する条件:

- `default` / `full` / `session` の実行範囲がテストされている
- `session` が `env-setup` / `install-tools` / `mise install` を呼ばない
- default setup が `install-tools` / `mise install` を呼ばない
- `mise install` が `MISE_YES=1` と `MISE_TRUSTED_CONFIG_PATHS` 付きで実行される
- `.env.remote` 復号は tool install と分離され、dotenvx がない場合も setup 全体を timeout させない

## 課題

### 1. Codex setup script が重すぎる

`codex-setup.sh` が full provisioning と session initialization の両方を担っている。

Environment Setup script としては妥当な処理もあるが、Codex maintenance script や手動再実行用途としては重い。

### 2. 環境変数の定義場所が曖昧

`CODEX_REMOTE`、`DOTENV_PRIVATE_KEY_REMOTE`、`CODEX_SETUP_PROFILE` のような値を script 内で作る設計にすると、Codex cloud の設定画面と責務が混ざる。

方針として、環境変数の指定は Codex Environment settings 側で行い、repository の script はその値を読むだけにする。

### 3. secret と environment variable の扱いを分ける必要がある

`DOTENV_PRIVATE_KEY_REMOTE` は `.env.remote` を復号するための鍵なので、agent phase に残さないほうがよい。
Codex cloud では secret は setup script 後に削除されるため、`DOTENV_PRIVATE_KEY_REMOTE` は secret として登録する。

一方、`CODEX_REMOTE=true` は secret ではないため、environment variable として登録する。
`CODEX_SETUP_PROFILE` は profile 分岐実装後に command 側で指定する。

### 4. `mise install` が非対話環境で止まる可能性がある

Codex cloud は非対話環境なので、`mise` の trust 確認や yes/no 確認が発生すると timeout しやすい。

対策として、`mise install` 実行時に以下を明示する。

- `MISE_YES=1`
- `MISE_TRUSTED_CONFIG_PATHS=<repo root>`

この対応は `scripts/install-tools.sh` に入れる。

ただし、`dotenvx` と `gh` はこの `mise install` の対象から外す。
Remote setup ではどちらも `mise` 経由で入れるのではなく、`.env.remote` 復号と GitHub CLI 初期化の前に cURL で直接利用可能にする。
候補は次のいずれか。

- Codex universal image に既にあればそれを使う
- なければ cURL で公式配布物を `~/.local/bin` に入れる
- `dotenvx` は `scripts/bootstrap-dotenvx.sh` が管理する
- `gh` は `scripts/bootstrap-gh.sh` が管理する
- `.env.remote` の復号と `.bashrc` 設定は `scripts/setup-remote-env.sh` が管理する

### 5. `dotenvx` を mise 管理にしている

`.env.remote` の復号は `GH_TOKEN` を作るための前提処理なので、`dotenvx` は remote bootstrap の必須依存として扱う。

現在の `.mise.toml` では `dotenvx = "latest"` になっているが、これは次の理由で不適切。

- `mise install` が timeout すると `dotenvx` も使えない
- `dotenvx` が使えないと `.env.remote` を復号できない
- `.env.remote` を復号できないと `GH_TOKEN` が作れない
- `GH_TOKEN` がないと `gh-setup.sh` が意味を持たない

したがって、`dotenvx` は `mise` の「その他開発ツール」から外し、remote setup の最初に cURL で直接 bootstrap する。

### 6. `gh` を npm install 前提にしない

結論として、公式 `gh` は npm install 前提にしない。

理由:

- npm の `gh` package は deprecated な Node GH であり、GitHub 公式 CLI `cli/cli` ではない
- GitHub 公式 CLI の一次情報では、Linux / macOS / Windows package、precompiled binaries、devcontainer feature などが案内されている
- `gh-setup.sh` は GitHub 公式 CLI の挙動を前提にしているため、npm の `gh` に置き換えると互換性が壊れる可能性が高い

方針:

- `gh` が Codex universal image に入っていればそれを使う
- なければ `gh` は公式 release binary から cURL で `~/.local/bin` に入れる
- `gh` の bootstrap も `mise install` から切り離す

### 7. cURL bootstrap に寄せる範囲

cURL 前提に寄せる対象:

- `dotenvx`
- `gh`

cURL bootstrap に寄せない対象:

- `qlty`
- `terraform`
- Bats などの test / lint 用 tool

Cloud 版 script の責務は次の順にする。

1. `scripts/bootstrap-dotenvx.sh` で `dotenvx` を bootstrap する
2. `scripts/bootstrap-gh.sh` で `gh` を bootstrap する
3. `scripts/setup-remote-env.sh` で `.env.remote` から `.env` を生成する
4. `scripts/setup-remote-env.sh` が `.env` を source して `GH_TOKEN` を使える状態にする
5. `gh-setup.sh` を実行する
6. `mise install` は qlty / terraform など後段の任意 tool install として扱う

### 8. script の責務境界

| Script                         | 責務                                           | やらないこと                         |
| ------------------------------ | ---------------------------------------------- | ------------------------------------ |
| `scripts/bootstrap-dotenvx.sh`  | `dotenvx` を `~/.local/bin` に入れる            | `.env.remote` の復号、`gh` install   |
| `scripts/bootstrap-gh.sh`       | GitHub 公式 CLI `gh` を `~/.local/bin` に入れる | `dotenvx` install、gh extensions setup |
| `scripts/setup-remote-env.sh`   | `.env.remote` から `.env` を生成し `.bashrc` を整える | tool install、gh extensions setup    |
| `.codex/hooks/gh-setup.sh`      | gh extensions setup                            | `dotenvx` install、`.env.remote` 復号 |
| `scripts/install-tools.sh`      | 任意の開発ツールを mise で入れる               | Cloud core tools install             |

### 9. `latest` 指定で再現性が低い

`.mise.toml` の一部 tool が `latest` 指定になっている。

初回 setup や cache invalidation 時に取得対象が変わるため、安定性を優先するなら pin する。

現時点で pin を検討する対象:

- `github:qltysh/qlty`

`dotenvx` は pin 以前に `mise` 管理から外す対象。

### 10. Codex cloud と Claude Code cloud の起動方式が違う

Claude Code は `.claude/settings.json` の `SessionStart` hook と `CLAUDE_ENV_FILE` で環境変数を永続化できる。

Codex cloud は Environment Setup script と maintenance script を cloud settings 側で明示設定し、agent phase に残す値は environment variables として設定する。

## 方針

### A. 環境変数は Codex Environment settings に寄せる

Web 画面で指定する内容は、前述の「Web 画面で設定する内容」を正とする。

Codex cloud の Environment variables:

```text
CODEX_REMOTE=true
```

Codex cloud の Secrets:

```text
DOTENV_PRIVATE_KEY_REMOTE=<.env.remote 用の復号鍵>
```

repository 側の script には `CODEX_REMOTE=true` や `DOTENV_PRIVATE_KEY_REMOTE=...` を直書きしない。
`CODEX_SETUP_PROFILE` は、default 以外を使うときだけ command 側で指定する。
Setup script では指定せず、Maintenance script の `session` や将来の `full` だけ明示する。

### B. setup profile を分ける

`.codex/hooks/codex-setup.sh` に profile を導入する。

```bash
bash .codex/hooks/codex-setup.sh
CODEX_SETUP_PROFILE=session bash .codex/hooks/codex-setup.sh
```

`default`:

- Codex cloud Environment Setup script の現在の推奨 profile
- `bootstrap-dotenvx`、`bootstrap-gh`、`setup-remote-env` を最初に実行する
- `install-tools` / `mise install` は実行しない
- `gh-setup` を実行する
- skills directory setup と git hooks setup を実行する

`full`:

- 将来、tool install が安定してから使う optional profile
- default の処理に加えて、`install-tools` を実行する
- ただし `dotenvx` / `gh` は `mise install` 対象にしない

`session`:

- Codex maintenance script / 手動再初期化用
- `mise install` は実行しない
- `bootstrap-gh` と `setup-remote-env` を実行する
- git hooks setup、skills directory setup、必要最小限の remote 調整だけ行う

### C. Codex cloud 側の設定を変更する

現時点では、Web 側に長い手順を直書きせず、軽量 profile の entrypoint だけを指定する。

Environment Setup script:

```bash
bash .codex/hooks/codex-setup.sh
```

Environment variables:

```text
CODEX_REMOTE=true
```

Secrets:

```text
DOTENV_PRIVATE_KEY_REMOTE=<.env.remote 用の復号鍵>
```

Maintenance script:

```bash
CODEX_SETUP_PROFILE=session bash .codex/hooks/codex-setup.sh
```

この設定で、full tool install を避けつつ `GH_TOKEN` を用意して gh setup を動かす。
さらに `~/.bashrc` から `.env` を source するため、agent phase でも通常の `gh` コマンドが `GH_TOKEN` を読める。

### D. secret は setup 中に `.env` へ必要最小限だけ展開する

`DOTENV_PRIVATE_KEY_REMOTE` は Codex secret として渡す。
setup script では `.env.remote` を復号し、`GH_TOKEN` だけを Git 管理されない `.env` に書き出す。

agent phase で `gh` を直接使えるように、`~/.bashrc` から repository の `.env` を source する。
`scripts/gh-remote` のようなラッパーは補助として使えるが、Web setup の主経路にはしない。
`DOTENV_PRIVATE_KEY_REMOTE` 自体を agent phase に残す設計にはしない。

### E. PATH 永続化は最小限にする

Codex Environment settings に置ける通常の環境変数は settings 側で管理する。

`~/.local/bin` や mise shims のように、setup で作られた path を agent terminal でも使いたい場合だけ `~/.bashrc` に追記する。

```bash
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/share/mise/shims:$PATH"
```

### F. Cloud core tools を cURL bootstrap にする

`dotenvx` と `gh` は `mise` 管理から外し、remote setup の最初に使える状態にする。

優先順位:

1. 既に `dotenvx` / `gh` がある場合はそれを使う
2. なければ cURL で公式配布物を `~/.local/bin` に入れる
3. それぞれ独立した bootstrap script で管理する

`dotenvx` は `GH_TOKEN` を用意するための前提で、`gh` は Remote 作業の主要 CLI なので、どちらも `scripts/install-tools.sh` の成功に依存させない。
ただし、1つの巨大な `bootstrap-cloud-core-tools.sh` にはまとめない。ファイル名と責務を一致させるため、`scripts/bootstrap-dotenvx.sh` と `scripts/bootstrap-gh.sh` に分ける。

### G. tool version pin を検討する

`.mise.toml` の `latest` を固定バージョンにする。

候補:

- `github:qltysh/qlty`

この変更は timeout 対策とは別コミットに分ける。
`dotenvx` と `gh` は pin 以前に `mise` 管理から外す対象。

## 実装ステップ

1. `.codex/hooks/codex-setup.sh` に default / `full` / `session` の profile 分岐を追加する
2. default profile は軽量な cloud setup とし、`install-tools` / `mise install` を呼ばない
3. Codex Web 画面の Setup script は `bash .codex/hooks/codex-setup.sh` だけにする
4. Codex Web 画面の Maintenance script は `CODEX_SETUP_PROFILE=session bash .codex/hooks/codex-setup.sh` だけにする
5. Environment variables はまず `CODEX_REMOTE=true` だけにする
6. 暫定設定で `.env` が生成され、`gh-setup.sh` が `GH_TOKEN` を持った状態で実行されることを確認する
7. `tests/codex-setup.bats` に profile ごとの実行範囲テストを追加する
8. `scripts/install-tools.sh` の `mise install` が `MISE_YES=1` / `MISE_TRUSTED_CONFIG_PATHS` を渡すことを確認する
9. `tests/install-tools-orchestrator.bats` で非対話化を検証する
10. `.mise.toml` から `dotenvx` と `gh` を外す
11. `scripts/bootstrap-dotenvx.sh` を追加する
12. `scripts/bootstrap-gh.sh` を追加する
13. `scripts/setup-remote-env.sh` を追加する
14. `scripts/env-setup.sh` は `DOTENV_PRIVATE_KEY_REMOTE` を「外から渡された secret」として読むだけにする
15. `.env.remote` 復号処理と `gh` bootstrap を tool install から分離し、Cloud core tools が `mise install` に依存しないことをテストする
16. Web 画面の Setup script / Maintenance script は単一 entrypoint のまま維持し、手順変更は `.codex/hooks/codex-setup.sh` 側で吸収する
17. 必要なら `.mise.toml` の `github:qltysh/qlty` などの `latest` を固定バージョンに変更する
18. Bats / qlty で検証する

## 検証項目

ローカル:

```bash
bats tests/install-tools-orchestrator.bats tests/codex-setup.bats tests/remote-env.bats
```

Codex cloud setup 後:

暫定の軽量 setup で確認すること:

```bash
test "${CODEX_REMOTE:-}" = "true"
test -f .env
grep -q '^GH_TOKEN=' .env
grep -F ".env" "$HOME/.bashrc"
git remote
gh auth status
bash -lc 'gh auth status'
```

期待値:

- setup が timeout しない
- `origin` が必要に応じて削除されている
- `.env.remote` から `.env` が生成されている
- `gh-setup.sh` 実行時に `GH_TOKEN` が export されている
- agent phase の Bash でも `~/.bashrc` 経由で `GH_TOKEN` を読める
- `mise install` は実行されない
- Web 側に複数 script の呼び出し順を直書きしない

profile 分岐実装後に確認すること:

```bash
test "${CODEX_REMOTE:-}" = "true"
test -f .env
env | grep '^DOTENV_PRIVATE_KEY' || true
grep -q '^GH_TOKEN=' .env
gh auth status
qlty --version
gh --version
dotenvx --version
```

期待値:

- agent phase で `DOTENV_PRIVATE_KEY_REMOTE` は見えない
- `.env` には AI 用の `GH_TOKEN` だけが入っている
- `gh` は agent phase の通常コマンドとして使える

timeout が解消しない場合:

- `mise install` のどの tool で止まっているか log を分ける
- `terraform` など重い tool を cloud setup から外す
- Codex universal image に既に入っている tool は install 対象から外す
- `latest` 指定を pin する

## 運用メモ

Web 側 secret には `GH_TOKEN` 実値ではなく `.env.remote` 用の `DOTENV_PRIVATE_KEY_REMOTE` を登録する。

`GH_TOKEN` を agent phase でも利用したい場合は、secret ではなく environment variable として直接渡すのではなく、setup script で `.env.remote` から作業用 `.env` を生成し、`gh` 実行時に明示的に読み込む。
