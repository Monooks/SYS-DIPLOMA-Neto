terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

resource "yandex_compute_instance" "web-1" {

  name                      = "linux-web1"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size     = 8
    }
  }

  network_interface {
    subnet_id          = "${yandex_vpc_subnet.subnet-1.id}"
    nat                = true
    security_group_ids = ["${yandex_vpc_security_group.private-sg.id}"]
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }
  
  scheduling_policy {
    preemptible = true
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

resource "yandex_compute_instance" "web-2" {

  name                      = "linux-web2"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size     = 8
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-2.id}"
    nat       = true
    security_group_ids = ["${yandex_vpc_security_group.private-sg.id}"]
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = true
  }      
}

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["192.168.20.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
}

resource "yandex_compute_instance" "elas-5" {

  name                      = "linux-elas5"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
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
    security_group_ids = ["${yandex_vpc_security_group.private-sg.id}"]
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "kib-6" {

  name                      = "linux-kib6"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size     = 8
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
    security_group_ids = ["${yandex_vpc_security_group.open-sg.id}"]
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

output "internal_ip_address_web_1" {
  value = yandex_compute_instance.web-1.network_interface.0.ip_address
}

output "external_ip_address_web_1" {
  value = yandex_compute_instance.web-1.network_interface.0.nat_ip_address
}

output "internal_ip_address_web_2" {
  value = yandex_compute_instance.web-2.network_interface.0.ip_address
}

output "external_ip_address_web_2" {
  value = yandex_compute_instance.web-2.network_interface.0.nat_ip_address
}

output "external_ip_address_l7" {
  value = yandex_alb_load_balancer.test-balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "internal_ip_address_prom_3" {
  value = yandex_compute_instance.prom-3.network_interface.0.ip_address
}

output "external_ip_address_prom_3" {
  value = yandex_compute_instance.prom-3.network_interface.0.nat_ip_address
}

output "internal_ip_address_graf_4" {
  value = yandex_compute_instance.graf-4.network_interface.0.ip_address
}

output "external_ip_address_graf_4" {
  value = yandex_compute_instance.graf-4.network_interface.0.nat_ip_address
}

output "internal_ip_address_elas_5" {
  value = yandex_compute_instance.elas-5.network_interface.0.ip_address
}

output "external_ip_address_elas_5" {
  value = yandex_compute_instance.elas-5.network_interface.0.nat_ip_address
}

output "internal_ip_address_kib_6" {
  value = yandex_compute_instance.kib-6.network_interface.0.ip_address
}

output "external_ip_address_kib_6" {
  value = yandex_compute_instance.kib-6.network_interface.0.nat_ip_address
}

output "internal_ip_address_bast_7" {
  value = yandex_compute_instance.bast-7.network_interface.0.ip_address
}

output "external_ip_address_bast_7" {
  value = yandex_compute_instance.bast-7.network_interface.0.nat_ip_address
}

resource "yandex_alb_target_group" "foo" {
  name           = "targetgroup"

  target {
    subnet_id    = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.web-1.network_interface.0.ip_address}"
  }

  target {
    subnet_id    = "${yandex_vpc_subnet.subnet-2.id}"
    ip_address   = "${yandex_compute_instance.web-2.network_interface.0.ip_address}"
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
  name               = "jimmy7"
  network_id         = "${yandex_vpc_network.network-1.id}"
  security_group_ids = ["${yandex_vpc_security_group.open-sg.id}"]

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

resource "yandex_compute_instance" "prom-3" {

  name                      = "linux-prom3"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size     = 8
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
    security_group_ids = ["${yandex_vpc_security_group.private-sg.id}"]
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = true
  }      
}

resource "yandex_compute_instance" "graf-4" {

  name                      = "linux-graf4"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size     = 8
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
    security_group_ids = ["${yandex_vpc_security_group.open-sg.id}"]
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = true
  }      
}

resource "yandex_vpc_security_group" "private-sg" {
  name        = "Private security group"
  description = "Web, Prometheus, Elasticsearch"
  network_id  = "${yandex_vpc_network.network-1.id}"

  ingress {
    protocol       = "ANY"
    description    = "Rule description 1"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Rule description 2"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "open-sg" {
  name        = "Open security group"
  description = "Grafana, Kibana, application load balancer"
  network_id  = "${yandex_vpc_network.network-1.id}"

  ingress {
    protocol       = "ANY"
    description    = "Rule description 1"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Rule description 2"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "ssh-sg" {
  name        = "SSH security group"
  description = "Bastion-host"
  network_id  = "${yandex_vpc_network.network-1.id}"

  ingress {
    protocol       = "ANY"
    description    = "Rule description 1"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Rule description 2"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "bast-7" {

  name                      = "linux-bast7"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size     = 8
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
    security_group_ids = ["${yandex_vpc_security_group.ssh-sg.id}"]
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}
