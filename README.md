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

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80`



