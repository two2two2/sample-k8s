FROM ruby:2.4.2

RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list

# リポジトリを更新し依存モジュールをインストール
RUN apt-get update -qq && \
    apt-get install -y build-essential apt-transport-https apt-utils

# node(8.x)
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && apt-get install -y nodejs

# yarn(stable)
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y yarn


# ルート直下にwebappという名前で作業ディレクトリを作成（コンテナ内のアプリケーションディレクトリ）
RUN mkdir /webapp
WORKDIR /webapp

# ホストのGemfileとGemfile.lockをコンテナにコピー
ADD Gemfile /webapp/Gemfile
ADD Gemfile.lock /webapp/Gemfile.lock

# bundle installの実行
RUN bundle install --jobs=4

# ホストのアプリケーションディレクトリ内をすべてコンテナにコピー
ADD . /webapp

# puma.sockを配置するディレクトリを作成
RUN mkdir -p tmp/sockets
RUN mkdir -p tmp/pids
RUN rm -f /webapp/tmp/pids/server.pid

RUN mkdir /webapp/log
RUN touch /webapp/log/development.log
RUN touch /webapp/log/production.log
RUN touch /webapp/log/puma.stdout.log
RUN touch /webapp/log/puma.stderr.log
RUN ln -sf /dev/stdout /webapp/log/development.log
RUN ln -sf /dev/stdout /webapp/log/production.log
RUN ln -sf /dev/stdout /webapp/log/puma.stdout.log
RUN ln -sf /dev/stderr /webapp/log/puma.stderr.log
RUN bundle exec rails assets:precompile
