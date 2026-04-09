# きかくさん

ライバーのための配信企画ジェネレータ

🔗 https://kikakusan.onrender.com/

## 概要

ジャンル（ざつだん・ゲーム・うた・おまかせ）と今日のきぶんを入力すると、AIが配信企画を10個提案するWebアプリ。プロフィールを登録しておくと、より自分に合った企画が出やすくなる。登録・ログイン不要、スマホで完結。

## 技術スタック

| カテゴリ | 技術 |
|---|---|
| バックエンド | Ruby on Rails 8 |
| フロントエンド | Stimulus.js |
| AI | Google Gemini API（gemなし、Net::HTTP直接呼び出し） |
| セキュリティ | rack-attack / Google reCAPTCHA v3 |
| ホスティング | Render（Starter） |
| データベース | Neon（PostgreSQL） |

## 機能

- ジャンル・きぶんを入力して配信企画を10個生成
- プロフィール登録（性別・年齢・家族構成・配信キャラ・リスナー層）でパーソナライズ
- プロフィールはlocalStorageに保存（ログイン不要）
- 企画のコピー・Xシェア
- IPごとのリクエスト制限（rack-attack）
- ボット対策（reCAPTCHA v3）

## 環境変数

```
GEMINI_API_KEY=
RECAPTCHA_SITE_KEY=
RECAPTCHA_SECRET_KEY=
GA_MEASUREMENT_ID=       # 省略可（未設定時はGAスクリプト読み込みなし）
```

## ローカル起動

```bash
bundle install
rails db:create db:migrate
bin/dev
```

## テスト

```bash
bundle exec rspec
```