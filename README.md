# Дипломная работа по профессии «`Системный администратор`» - `Емельянов Михаил`

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 
* [Решение](#Решение)
---------
## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible. 

Параметры виртуальной машины (ВМ) подбирайте по потребностям сервисов, которые будут на ней работать. 

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Prometheus. На каждую ВМ из веб-серверов установите Node Exporter и Nginx Log Exporter. Настройте Prometheus на сбор метрик с этих exporter.

Создайте ВМ, установите туда Grafana. Настройте её на взаимодействие с ранее развернутым Prometheus. Настройте дешборды с отображением метрик, минимальный набор — Utilization, Saturation, Errors для CPU, RAM, диски, сеть, http_response_count_total, http_response_size_bytes. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Настройте все security groups на разрешение входящего ssh из этой security group. Эта вм будет реализовывать концепцию bastion host. Потом можно будет подключаться по ssh ко всем хостам через этот хост.

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)

# Решение

## 1. Создание виртуальных машин для устройства веб-серверов nginx.

Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Для выполнения данной работы я использую терминал с установленной на него системой Ubuntu 22.04.
С данного терминала я выхожу в сеть интернет для доступа к Yandex.Cloud.

На терминале устанавливаю Terraform по инструкции с Yandex.Cloud.

Создаю файл main.tf с учетом условий:

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

[main.tf](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/main.tf)

При terraform apply создаются две ВМ в разных зонах доступности. С Ubuntu 20.04 LTS  на борту. Это наши веб-сервера. А так же все остальные необходимые ресурсы.

Terraform outputs:

[external_ip_address_bast_7 = "158.160.56.142"](http://158.160.56.142)

[external_ip_address_elas_5 = "130.193.48.161"](http://130.193.48.161)

[external_ip_address_graf_4 = "51.250.70.123"](http://51.250.70.123)

[external_ip_address_kib_6 = "158.160.45.56"](http://158.160.45.56)

[external_ip_address_l7 = "158.160.130.195"](http://158.160.130.195)

[external_ip_address_prom_3 = "158.160.38.127"](http://158.160.38.127)

[external_ip_address_web_1 = "84.201.132.138"](http://84.201.132.138)

[external_ip_address_web_2 = "84.201.140.19"](http://84.201.140.19)

[internal_ip_address_bast_7 = "192.168.10.9"](http://192.168.10.9)

[internal_ip_address_elas_5 = "192.168.10.4"](http://192.168.10.4)

[internal_ip_address_graf_4 = "192.168.10.32"](http://192.168.10.32)

[internal_ip_address_kib_6 = "192.168.10.23"](http://192.168.10.23)

[internal_ip_address_prom_3 = "192.168.10.31"](http://192.168.10.31)

[internal_ip_address_web_1 = "192.168.10.16"](http://192.168.10.16)

[internal_ip_address_web_2 = "192.168.20.34"](http://192.168.20.34)

Теперь надо установить Ansible на терминал.
И с его помощью установить на веб-сервера nginx, а также залить сайт на них.

Устанавливаем Ansible на терминал.
Создаем конфигурационный файл ansible.cfg

[ansible.cfg](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/ansible.cfg)

Описываем окружение inventory.ini. Внешние IP адреса берем из terraform output.

[inventory.ini](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/inventory.ini)

Описываем playbook.yaml и роль:

[nginx_role.zip](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/nginx_role.zip)

Вводим команды:

```bash
ansible all -m ping
ansible-playbook -b /home/imonooks/Загрузки/Task4/playbook4.yam
```

Тестируем сайт:

```
curl -v 158.160.132.187:80
```

[external_ip_address_l7 = "158.160.130.195"](http://158.160.130.195) - внешний адрес L7 балансировщика.

---

## 2. Устройство мониторинга посредством Prometheus и Grafana.

### Мониторинг
Создайте ВМ, разверните на ней Prometheus. На каждую ВМ из веб-серверов установите Node Exporter и Nginx Log Exporter. Настройте Prometheus на сбор метрик с этих exporter.

Создайте ВМ, установите туда Grafana. Настройте её на взаимодействие с ранее развернутым Prometheus. Настройте дешборды с отображением метрик, минимальный набор — Utilization, Saturation, Errors для CPU, RAM, диски, сеть, http_response_count_total, http_response_size_bytes. Добавьте необходимые tresholds на соответствующие графики.

#### Cтавим Prometheus

Вводим команды:

```bash
ssh user@158.160.125.19 -i id_rsa
sudo -i
useradd --no-create-home --shell /bin/false prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz
tar xvfz prometheus-2.47.1.linux-amd64.tar.gz
cd prometheus-2.47.1.linux-amd64/
mkdir /etc/prometheus
mkdir /var/lib/prometheus
cp ./prometheus promtool /usr/local/bin/
cp -R ./console_libraries /etc/prometheus
cp -R ./consoles /etc/prometheus
cp ./prometheus.yml /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
nano /etc/systemd/system/prometheus.service
```
[prometheus.service](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/prometheus.service)

```
chown -R prometheus:prometheus /var/lib/prometheus
systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl status prometheus
```
![Скриншот-1](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/dip_1.png)

ноде экспортер
```bash
# ssh user@158.160.125.19 -i id_rsa
$ sudo -i
# sudo useradd --no-create-home --shell /bin/false prometheus
# wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
# tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
# cd node_exporter-1.6.1.linux-amd64/
# mkdir /etc/prometheus
# mkdir /etc/prometheus/node-exporter
# cp ./* /etc/prometheus/node-exporter
# chown -R prometheus:prometheus /etc/prometheus/node-exporter/
# nano /etc/systemd/system/node-exporter.service
```
[Unit]
Description=Node Exporter Lesson 9.4
After=network.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/etc/prometheus/node-exporter/node_exporter
[Install]
WantedBy=multi-user.target
```bash
# sudo systemctl enable node-exporter
# sudo systemctl start node-exporter
# sudo systemctl status node-exporter
```
правим конфиг prometheus
```bash
# ssh user@158.160.125.19 -i id_rsa
$ sudo -i
# nano /etc/prometheus/prometheus.yml
```
scrape_configs:
  — job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      — targets: ['localhost:9090', 'localhost:9100']
```bash
# systemctl restart prometheus
# systemctl status prometheus
```
nginxlog-exporter
```bash
# ssh user@158.160.125.19 -i id_rsa
$ sudo -i
# wget https://github.com/martin-helmich/prometheus-nginxlog-exporter/releases/download/v1.9.2/prometheus-nginxlog-exporter_1.9.2_linux_amd64.deb
# apt install ./prometheus-nginxlog-exporter_1.9.2_linux_amd64.deb
# wget -O /etc/systemd/system/prometheus-nginxlog-exporter.service https://raw.githubusercontent.com/martin-helmich/prometheus-nginxlog-exporter/master/res/package/prometheus-nginxlog-exporter.service
# nano /etc/systemd/system/prometheus-nginxlog-exporter.service
```
[Unit]
Description=NGINX metrics exporter for Prometheus
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/sbin/prometheus-nginxlog-exporter -config-file /etc/prometheus-nginxlog-exporter.hcl
Restart=always
ProtectSystem=full
CapabilityBoundingSet=
User=prometheus
Group=prometheus
Type=simple

[Install]
WantedBy=multi-user.target
```bash
# nano /etc/nginx/nginx.conf
```
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
        # multi_accept on;
}

http {

        ##
        # Basic Settings
        ##

        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;
        # server_tokens off;

        # server_names_hash_bucket_size 64;
        # server_name_in_redirect off;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        ##
        # SSL Settings
        ##

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;

        # logging config
        log_format custom   '$remote_addr - $remote_user [$time_local] '
                            '"$request" $status $body_bytes_sent '
                            '"$http_referer" "$http_user_agent" "$http_x_forwarded_for"';
        ##Написать хо
        # Logging Settings
        ##

        access_log /var/log/nginx/access.log custom;
        error_log /var/log/nginx/error.log;

        ##
        # Gzip Settings
        ##

        gzip on;

        # gzip_vary on;
        # gzip_proxied any;
        # gzip_comp_level 6;
        # gzip_buffers 16 8k;
        # gzip_http_version 1.1;
        # gzip_types text/plain text/css application/json application/javascript text/xml application/xml appli>

	##
        # Virtual Host Configs
        ##

        include /etc/nginx/conf.d/myapp.conf;
}


#mail {
#       # See sample authentication script at:
#       # http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
# 
#       # auth_http localhost/auth.php;
#       # pop3_capabilities "TOP" "USER";
#       # imap_capabilities "IMAP4rev1" "UIDPLUS";
# 
#       server {
#               listen     localhost:110;
#               protocol   pop3;
#               proxy      on;
#       }
# 
#       server {
#               listen     localhost:143;
#               protocol   imap;
#               proxy      on;
#       }
#}
```bash
# rm -rf /etc/nginx/sites-enabled/default
# nano /etc/nginx/conf.d/myapp.conf
```
server {

  listen 80 default_server;
  # remove the escape char if you are going to use this config
  server_name \_;

  root /var/www/html;
  index index.html index.htm index.nginx-debian.html;

  location / {
    try_files $uri $uri/ =404;
  }

}
```bash
# systemctl restart nginx
# systemctl status nginx
# systemctl daemon-reload
# chown -R prometheus:prometheus /var/log/nginx/access.log
# systemctl restart prometheus-nginxlog-exporter
# systemctl status prometheus-nginxlog-exporter
```
ставим графану
```bash
# ssh user@158.160.125.19 -i id_rsa
$ sudo -i
# apt-get install -y adduser libfontconfig1 musl
# wget https://dl.grafana.com/oss/release/grafana_10.1.5_amd64.deb
# dpkg -i grafana_10.1.5_amd64.deb
# systemctl enable grafana-server
# systemctl start grafana-server
# systemctl status grafana-server
```

fd8nhb6fd0hpl40gm797 - ключ от дебиана

ставим Elasticsearch:
```bash
# ssh user@158.160.125.19 -i id_rsa
$ sudo -i
# apt update && apt install gnupg apt-transport-https
# wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
# echo "deb [trusted=yes] https://mirror.yandex.ru/mirrors/elastic/7/ stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
# apt update && apt-get install elasticsearch
# systemctl daemon-reload
# systemctl enable elasticsearch.service
# systemctl start elasticsearch.service
# systemctl status elasticsearch.service
# curl 'localhost:9200/_cluster/health?pretty'
```
настройка эластикаНаписать хо
```bash
# nano /etc/elasticsearch/elasticsearch.yml
```

cluster.name: diplomaneto
node.name: node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
discovery.seed_hosts: ["127.0.0.1", "[::1]"]
```bash
# systemctl restart elasticsearpaths:
    - /var/log/*.log
ch.service
# systemctl status elasticsearch.service
```

установка Kibana:
```bash
# ssh user@158.160.125.19 -i id_rsa
$ sudo -i
# apt update && apt install gnupg apt-transport-https
# wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
# echo "deb [trusted=yes] https://mirror.yandex.ru/mirrors/elastic/7/ stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
# apt update && apt-get install kibana
# systemctl daemon-reload
# systemctl enable kibana.service
# systemctl start kibana.service
# systemctl status kibana.service
```
правим Кибану:
```bash
# nano /etc/kibana/kibana.yml
```
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://84.201.134.46:9200"]

в браузере вводим:

http://84.201.158.212:5601/app/dev_tools#/console

делаем запрос к Эластику:

GET /_cluster/health?pretty

Ставим файлбитсы на сервера c nginx:
```bash
# ssh user@158.160.125.19 -i id_rsa
$ sudo -i
# apt update && apt install gnupg apt-transport-https
# wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
# echo "deb [trusted=yes] https://mirror.yandex.ru/mirrors/elastic/7/ stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
# apt update && apt-get install filebeat
# systemctl daemon-reload
# systemctl enable filebeat.service
# systemctl start filebeat.service
# systemctl status filebeat.service
```
Правим конфиг Фаилбитс:
```bash
# nano /etc/filebeat/filebeat.yml
```
  enabled: true
  paths:
    - /var/log/nginx/*.log
    
    
setup.kibana:
  host: "84.201.158.212:5601"

output.elasticsearch:
  hosts: ["84.201.134.46:9200"]
  
```bash
# systemctl restart filebeat.service
# systemctl status filebeat.service
```
Создаем группы безопасности






















