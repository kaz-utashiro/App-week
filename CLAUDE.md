# App-week

Colorful calendar command for ANSI terminals.

## Build & Test

- Minilla 管理のディストリビューション
- `minil build` でビルド（META.json, README.md 等を再生成）
- `prove -l t/` でテスト実行
- リリースは `minilla-release` スキルに従う

## Perl Version

- 最小バージョン: 5.24
- `\N{NBSP}` 等の名前付き Unicode 文字を使用しているため

## Key Design Decisions

- フレーム部分のスペースは NBSP (U+00A0) を使用
  - sl-2026 のスイープ検出がカレンダーフレームを認識できるようにするため
- テスト (`t/Util.pm`) では出力の NBSP をスペースに正規化して比較

## File Structure

- `script/week` — エントリポイントおよびマニュアル (POD)
- `lib/App/week.pm` — コアモジュール
- `lib/App/week/CalYear.pm` — カレンダー生成・キャッシュ
- `lib/App/week/Util.pm` — ユーティリティ関数
- `lib/App/week/default.pm` — デフォルト設定・autoload オプション
- `lib/App/week/colors.pm` — カラーテーマ
- `lib/App/week/mlb.pm` — MLB カラーテーマ
- `lib/App/week/npb.pm` — NPB カラーテーマ
- `lib/App/week/olympic.pm` — オリンピックカラーテーマ

## CI

- GitHub Actions (`.github/workflows/test.yml`)
- Perl 5.24, 5.28, 5.34, 5.40 でテスト
- CI 環境に `cal` コマンドがないため関連の警告は正常
