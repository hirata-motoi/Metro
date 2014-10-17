# Metro

---
## setup

Metroをcloneした後に、セットアップスクリプトを実行する。
セットアップスクリプト内では、ファイル名、ディレクトリ名、各ファイル内で使われている変数名の変更、.gitの削除を行う。

```
git clone git@github.com:hirata-motoi/Metro.git Component
cd Component
sh script/setup Component
cpanm --installdeps .
perl script/component-server -p 5000
```

## [grunt](http://gruntjs.com/)

- 各種ビルドツール
- Gruntfile.js or Gruntfile.coffeeで設定

### モジュールの追加

    $ npm install --save-dev [package_name] # package.jsonにパッケージの情報が追記される

### リアルタイム監視

    $ grunt watch

---

## [bower](http://bower.io/)

- web用のパッケージマネージャ
- bower.jsonで設定

### ライブラリの追加

    $ bower install --save [library_name or git_repository or source_url] # bower.jsonにパッケージの情報が追記される

### 留意事項

そのままだと不要なファイル多く使えないのでgrunt-bower-taskを利用

### ライブラリのインストール

    $ grunt bower:install

---

## [bundler](http://bundler.io/)

- プロジェクト内で使うRubygemsを管理するツール
- Gemfileで設定

### ライブラリのインストール

    $ cd [project_directry] (--path [library_path])
    $ bundle install --path vendor/bundle

### rubyスクリプトの実行

    $ bundle exec ruby [ruby_script]


