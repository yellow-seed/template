# Template Project Constitution

このドキュメントは、AIエージェントを活用した開発における基本原則を定義します。

## Core Principles

### I. Spec-First Development

仕様書を先に作成し、承認後に実装を行う。

- 機能追加・変更は仕様書（spec.md）から開始する
- 仕様書は「何を」「なぜ」に焦点を当て、「どのように」は計画フェーズで決定する
- 仕様書はビジネスステークホルダーが理解できる言葉で記述する

### II. Conventional Commits

コミットメッセージは[Conventional Commits](https://www.conventionalcommits.org/)形式に従う。

- Type: feat, fix, docs, style, refactor, perf, test, chore
- Subject: 50文字以内、命令形、小文字開始、ピリオドなし
- Body: 変更の理由や方法を説明（オプション）

### III. Test-Driven Quality

テストによる品質保証を重視する。

- 重要な機能にはテストを作成する
- Prettierによるコードフォーマットを維持する
- CIパイプラインでの自動チェックを通過させる

### IV. Documentation as Code

ドキュメントもコードと同様に管理する。

- AGENTS.md / CLAUDE.md でAIエージェントへの指示を管理
- スキルファイル (.github/skills/) で再利用可能な知識を蓄積
- Markdownファイルは Prettier でフォーマットする

### V. Simplicity

シンプルさを優先する。

- YAGNIの原則：必要になるまで実装しない
- 最小限の変更で目的を達成する
- 過度な抽象化を避ける

## Development Workflow

### Feature Development Flow

1. `/speckit.specify` - 仕様書を作成
2. `/speckit.clarify` - 不明点を明確化（オプション）
3. `/speckit.plan` - 技術的な実装計画を策定
4. `/speckit.tasks` - タスクリストを生成
5. `/speckit.implement` - 実装を実行

### Code Review Standards

- 仕様書との整合性を確認
- テストの網羅性を確認
- コーディング規約への準拠を確認

## Governance

- この Constitution はプロジェクトの基本原則として機能する
- 変更には理由の文書化とチームの合意が必要
- 詳細な開発ガイダンスは AGENTS.md を参照

**Version**: 1.0.0 | **Ratified**: 2026-01-29 | **Last Amended**: 2026-01-29
