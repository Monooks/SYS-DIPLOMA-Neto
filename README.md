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
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

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

## Решение

1. Создание виртуальных машин для устройства веб-серверов nginx.

#### Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Для выполнения данной работы я использую терминал с установленной на него системой Ubuntu 22.04.
С данного терминала я выхожу в сеть интернет для доступа к Yandex.Cloud.

На терминале устанавливаю Terraform по инструкции с Yandex.Cloud.

Создаю файл main.tf с учетом условий:

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

[main.tf](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/main.tf)

```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

resource "yandex_compute_instance" "vm-1" {

  name                      = "linux-vm1"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size     = 10
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
}

resource "yandex_compute_instance" "vm-2" {

  name                      = "linux-vm2"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-b"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size     = 10
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-2.id}"
    nat       = true
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }
}

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["192.168.20.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

output "internal_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.ip_address
}

output "external_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
}

#output "external_ip_address_l7" {
#  value = yandex_alb_load_balancer.test-balancer.network_interface.0.nat_ip_address
#}

resource "yandex_alb_target_group" "foo" {
  name           = "targetgroup"

  target {
    subnet_id    = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.vm-1.network_interface.0.ip_address}"
  }

  target {
    subnet_id    = "${yandex_vpc_subnet.subnet-2.id}"
    ip_address   = "${yandex_compute_instance.vm-2.network_interface.0.ip_address}"
  }
}

resource "yandex_alb_backend_group" "test-backend-group" {
  name                     = "backendgroup"
  session_affinity {
    connection {
      source_ip = true
    }
  }

  http_backend {
    name                   = "back1"
    weight                 = 1
    port                   = 80
    target_group_ids       = ["${yandex_alb_target_group.foo.id}"]
    load_balancing_config {
      panic_threshold      = 90
    }
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15
      http_healthcheck {
        path               = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "tf-router" {
  name          = "groovy"
  labels        = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "my-virtual-host" {
  name                    = "billy"
  http_router_id          = yandex_alb_http_router.tf-router.id
  route {
    name                  = "mainroute"
    http_route {
      http_route_action {
        backend_group_id  = "${yandex_alb_backend_group.test-backend-group.id}"
        timeout           = "60s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "test-balancer" {
  name        = "jimmy7"
  network_id  = "${yandex_vpc_network.network-1.id}"
#  security_group_ids = ["${yandex_vpc_security_group.default.id}"]

 allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    }
  }

#  allocation_policy {
#    location {
#      zone_id   = "ru-central1-b"
#      subnet_id = "yandex_vpc_subnet.subnet-2.id" 
#    }
#  }

  listener {
    name = "bobby"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = "${yandex_alb_http_router.tf-router.id}"
      }
    }
  }

#  log_options {
#    log_group_id = "<идентификатор_лог-группы>"
#    discard_rule {
#      http_codes          = ["<HTTP-код>"]
#      http_code_intervals = ["<класс_HTTP-кодов>"]
#      grpc_codes          = ["<gRPC-код>"]
#      discard_percent     = <доля_отбрасываемых_логов>
#    }
#  }
}
```
При terraform apply создаются две ВМ в разных зонах доступности. С Ubuntu 20.04 LTS  на борту. Это наши веб-сервера.

Теперь надо установить Ansible на терминал.
И с его помощью установить на веб-сервера nginx, а также залить сайт на них.

Устанавливаем Ansible на терминал.
Создаем конфигурационный файл ansible.cfg
```yaml
[defaults]
inventory = /root/inventory.ini
remote_user = user
#gathering = explicit
forks = 5
private_key_file = /root/id_rsa

[privilege_escalation]
#become = true
become_user = root
become_method = sudo
```
Описываем окружение inventory.ini. Внешние IP адреса берем из terraform output.
```yaml
[webserwers:children]
nginx1
nginx2

[nginx1]
84.201.132.141

[nginx2]
158.160.9.93
```
Описываем playbook.yaml
```yaml
---
- name: "Get up nginx"
  hosts: all
  roles:
    - nginx
...
```
В папке "defaults" роли "nginx" редактируем main.yml
```yaml
---
# defaults file for apache2
port: "80"
...
```
В папке "tasks" роли "nginx" редактируем main.yml
```yaml
---
# tasks file for nginx

- name: "Install nginx"
  apt:
    name: "nginx"
    state: present
    update_cache: yes
- name: "Add Index page"
  template:
    src: "index.html.j2"
    dest: "/var/www/html/index.html"
    owner: root
    group: root
    mode: 0755
- name: "Start nginx"
  service:
    name: nginx
    state: restarted
    enabled: yes
- name: "Port {{ port }}"
  wait_for:
    port: "{{ port }}"
    delay: 10
...
```
В папке "templates" роли "nginx" редактируем index.html.j2.
```html
<!DOCTYPE html>
<html lang="ru" >
<head>
<meta charset="UTF-8">
<title>Diploma-sys-18</title>
<style type="text/css">
a{
color: #fff;
text-decoration: none;
}
html{
background: #FFF8CC;
min-height: 100%;
font-family: Helvetica;
display: flex;
flex-direction: column;
}
body{
margin: 0;
padding: 0 15px;
display: flex;
flex-direction: column;
flex: auto;
}
h1{
margin-top: 0;
}
h1, p{
color: #006064;
}
img{
border: 0;
}
.header{
width: 100%;
min-width: 460px;
max-width: 960px;
margin: 0 auto 30px;
padding: 30px 0 10px;
display: flex;
flex-wrap: wrap;
justify-content: space-between;
box-sizing: border-box;
}
.logo{
font-size: 1.5rem;
color: #fff;
text-decoration: none;
margin: 5px 0 0 5px;
justify-content: center;
align-items: center;
display: flex;
flex: none;
align-items: center;
background: #839FFF;
width: 130px;
height: 50px;
}
.nav{
margin: -5px 0 0 -5px;
display: flex;
flex-wrap: wrap;
}
.nav-item{
background: #BDC7FF;
width: 130px;
height: 50px;
font-size: 1.5rem;
color: #fff;
text-decoration: none;
display: flex;
margin: 5px 0 0 5px;
justify-content: center;
align-items: center;
}
.sqr{
height: 300px;
width: 300px;
background: #FFDB89;
}

.main{
width: 100%;
min-width: 460px;
max-width: 960px;
margin: auto;
flex: auto;
box-sizing: border-box;
}
.box{
font-size: 1.25rem;
line-height: 1.5;
margin: 0 0 40px -50px;
display: flex;
flex-wrap: wrap;
justify-content: center;
}
.box-base{
margin-left: 50px;
flex: 1 0 430px;
}
.box-side{
margin-left: 50px;
font: none;
}
.box-img{
max-width: 100%;
height: auto;
}
.content{
margin-bottom: 30px;
display: flex;
flex-wrap: wrap;
}
.banners{
flex: 1 1 200px;
}
.banner{
background: #FFDB89;
width: 100%;
min-width: 100px;
min-height: 200px;
font-size: 3rem;
color: #fff;
margin: 0 0 30px 0;
display: flex;
justify-content: center;
align-items: center;
}
.posts{
margin: 0 0 30px 30px;
flex: 1 1 200px;
}
.comments{
margin: 0 0 30px 30px;
flex: 1 1 200px;
}
.comment{
display: flex;
}
.comment-side{
padding-right: 20px;
flex: none;
}
.comment-base{
flex: auto;
}
.comment-avatar{
background: #FFA985;
width: 50px;
height: 50px;
}
.footer{
background: #FF3366;
width: 100%;
max-width: 960px;
min-width: 460px;
color: #fff;
margin: auto;
padding: 15px;
box-sizing: border-box;
}

@media screen and  (max-width: 800px) {
.banners{
margin-left: -30px;
display: flex;
flex-basis: 100%;
}
.banner{
margin-left: 30px;
}
.posts{
margin-left: 0;
}
}
@media screen and  (max-width: 600px) {
.content{
display: block;
}
.banners{
margin: 0;
display: block;
}
.banner{
margin-left: 0;
}
.posts{
margin: 0;
}
}
</style>
</head>
<body>
<header class="header">
<a class="logo">
SYS-18
</a>
<nav class="nav">
<a href="#posts" class="nav-item">Студенты</a>
<a href="#comments" class="nav-item">Кураторы</a>
<a href="#footer" class="nav-item">Аспиранты</a>
<a href="#posts" class="nav-item">Эксперты</a>
</nav>

</header>
<main class="main">
<div class="box">
<div class="box-base">
<h1>Диплом Емельянова Михаила Вадимовича группы SYS-18</h1>
<p>Диплом - это очень круто!</p>
</div>
<div class="box-side">
<div class="sqr">

</div>
</div>
</div>
<div class="content">
<div class="banners">
<div class="banner">Нетология - ...</div>
<div class="banner">...это наше...</div>
<div class="banner">...всё!</div>
</div>
<div class="posts"  id="posts">
<div class="post">
<h1>Создаем сайт!</h1>
<p>Терраформом и Энсиблом делаем вебсервера с Нджинксом!</p>
</div>
<div class="post">
<h1>Делаем мониторинг!</h1>
<p>Да прибудет с нами сила Прометьюса и красота Графаны! </p>
</div>
<div class="post">
<h1>Ну и Логи, кудой без них!</h1>
<p>Логи разные нужны, логи разные важны! ЕЛК нам в помощь!</p>
</div>
</div>
<div class="comments"  id="comments">
<div class="comment">
<div class="comment-side">
<div class="comment-avatar">

</div>
</div>
<div class="comment-base">
<h1 class="comment-title">У меня лапки!</h1>
<p>Главное не опускать руки если не получается!</p>
</div>
</div>
<div class="comment">
<div class="comment-side">
<div class="comment-avatar">

</div>
</div>
<div class="comment-base">
<h1 class="comment-title">Гугли, блеать!</h1>
<p>Ищите инфу! Это главный навык сисодмина!</p>
</div>
</div>
<div class="comment">
<div class="comment-side">
<div class="comment-avatar">

</div>
</div>
<div class="comment-base">
<h1 class="comment-title">Время пробовать и ошибаться!</h1>
<p>Тяжело в учении - легко на работе!</p>
</div>
</div>
</div>
</div>
</main>
<footer class="footer"  id="footer">
Я замаялся это пилить! Можно зачет автоматом?
</footer>
</body>
</html>
```
Протестируйте сайт
`curl -v <публичный IP балансера>:80`
![Скриншот-1](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/dip_1.png)
![Скриншот-2](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/dip_2.png)
![Скриншот-2](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/dip_3.png)
![Скриншот-2](https://github.com/Monooks/SYS-DIPLOMA-Neto/blob/main/img/dip_4.png)
---
ставим prometheus:
```bash
# ssh user@158.160.125.19 -i id_rsa
$ sudo -i
# useradd --no-create-home --shell /bin/false prometheus
# wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz
# tar xvfz prometheus-2.47.1.linux-amd64.tar.gz
# cd prometheus-2.47.1.linux-amd64/
# mkdir /etc/prometheus
# mkdir /var/lib/prometheus
# cp ./prometheus promtool /usr/local/bin/
# cp -R ./console_libraries /etc/prometheus
# cp -R ./consoles /etc/prometheus
# cp ./prometheus.yml /etc/prometheus
# chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
# chown prometheus:prometheus /usr/local/bin/prometheus
# chown prometheus:prometheus /usr/local/bin/promtool
# nano /etc/systemd/system/prometheus.service
```
[Unit]
Description=Prometheus Service Netology Diploma
After=network.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries
ExecReload=/bin/kill -HUP $MAINPID Restart=on-failure
[Install]
WantedBy=multi-user.target
```
# chown -R prometheus:prometheus /var/lib/prometheus
# systemctl enable prometheus
# sudo systemctl start prometheus
# sudo systemctl status prometheus
```
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






















