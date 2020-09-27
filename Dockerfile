FROM ruby:2.7.1
WORKDIR /app
COPY Gemfile /app
COPY env_template /env

RUN /usr/local/bin/bundle install
RUN /usr/bin/apt-get update
RUN /usr/bin/apt-get -y install locales locales-all vim
RUN apt install -y cron

RUN (crontab -l; echo "*/10 * * * * . /env; /usr/local/bin/ruby /app/upload.rb >> /var/tmp/upload.txt 2>&1") | crontab


ARG CLIENT_ID
ARG CLIENT_SECRET
ARG REFRESH_TOKEN

ENV CLIENT_ID="$CLIENT_ID"
ENV CLIENT_SECRET="$CLIENT_SECRET"
ENV REFRESH_TOKEN="$REFRESH_TOKEN"

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8

CMD /etc/init.d/cron start && sed -i "s/{replace_client_id}/${CLIENT_ID}/g" /env && sed -i "s/{replace_client_secret}/${CLIENT_SECRET}/g" /env && sed -i "s,{replace_refresh_token},${REFRESH_TOKEN},g" /env && tail -f /dev/null
