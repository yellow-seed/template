## なぜやるか

worktree を活用した並列開発により、複数の変更を同時に進められるようになった一方で、CI がオールグリーンの状態でもマージ待ちになっている PR がボトルネックになっている。マージ作業を効率化し、レビュアーや作成者の待ち時間を削減するために、CI 状態・レビュー承認・コンフリクトの有無を自動判定して安全にマージ実行できるゲートキーパースキルが必要。

## Ref

- [git-branch-worktree スキル](../../.agents/skills/git-branch-worktree/SKILL.md)
- [pull-request スキル](../../.agents/skills/pull-request/SKILL.md)
- [GitHub rulesets](../../.github/rulesets/branch-protection-ruleset.json)
