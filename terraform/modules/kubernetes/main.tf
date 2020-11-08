provider "kubernetes" {}

#######################
#### Elasticsearch ####
#######################

resource "kubernetes_stateful_set" "elasticsearch_ss" {
  metadata {
    name = "elasticsearch-ss"
    namespace = "default"
    labels = {
      app = "elasticsearch"
      role = "data"
    }
  }

  spec {
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5
    service_name = "elasticsearch-service"

    selector {
      match_labels = {
        app = "elasticsearch"
        role = "data"
      }
    }

    template {
      metadata {
        labels = {
          app = "elasticsearch"
          role = "data"
        }
        annotations = {}
      }

      spec {
        init_container {
          name              = "fix-permissions"
          image             = "busybox:latest"
          image_pull_policy = "IfNotPresent"
          command           = ["sh", "-c", "chown -R 1000:1000 /usr/share/elasticsearch/data"]
          security_context  {
            privileged = true
          }
          volume_mount {
            name       = "aws-managed-disk"
            mount_path = "/usr/share/elasticsearch/data"
            sub_path   = ""
          }
        }

        init_container {
          name              = "increase-vm-max-map"
          image             = "busybox:latest"
          image_pull_policy = "IfNotPresent"
          command           = ["sysctl", "-w", "vm.max_map_count=262144"]
          security_context  {
            privileged = true
          }
          volume_mount {
            name       = "aws-managed-disk"
            mount_path = "/usr/share/elasticsearch/data"
            sub_path   = ""
          }
        }

        init_container {
          name              = "increase-fd-ulimit"
          image             = "busybox:latest"
          image_pull_policy = "IfNotPresent"
          command           = ["sh", "-c", "ulimit -n 65536"]
          security_context  {
            privileged = true
          }
          volume_mount {
            name       = "aws-managed-disk"
            mount_path = "/usr/share/elasticsearch/data"
            sub_path   = ""
          }
        }

        container {
          name              = "elasticsearch-custom"
          image             = "docker.elastic.co/elasticsearch/elasticsearch:7.6.1"
          image_pull_policy = "Always"

          env {
            name  = "environment"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }  
          }

          env {
            name  = "node.name"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }  
          }

          env {
            name  = "cluster.name"
            value = "elasticsearch-cluster"
          }

          env {
            name  = "node.master"
            value = "true"
          }

          env {
            name  = "node.data"
            value = "true"
          }

          env {
            name  = "ES_JAVA_OPTS"
            value = "-Xms500m -Xmx500m"
          }

          env {
            name  = "path.logs"
            value = "/var/log"
          }

          env {
            name  = "path.data"
            value = "/usr/share/elasticsearch/data"
          }

          env {
            name  = "xpack.security.enabled"
            value = "false"
          }

          env {
            name  = "path.repo"
            value = "/usr/share/"
          }

          env {
            name  = "discovery.zen.ping.unicast.hosts"
            value = "elasticsearch-custom"
          }

          env {
            name  = "discovery.type"
            value = "single-node"
          }

          port {
            container_port = 9200
          }

          port {
            container_port = 9300
          }

          resources {
            limits {
              cpu    = "2000m"
              memory = "2000Mi"
            }

            requests {
              cpu    = "1000m"
              memory = "1000Mi"
            }
          }

          volume_mount {
            name       = "aws-managed-disk"
            mount_path = "/usr/share/elasticsearch/data"
            sub_path   = ""
          }

        }

        termination_grace_period_seconds = 10
      }
    }

    update_strategy {
      type = "RollingUpdate"

    }

    volume_claim_template {
      metadata {
        name = "aws-managed-disk"
        labels = {
          app = "elasticsearch"
        }
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "10Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "elasticsearch_service" {

  metadata {
    name = "elasticsearch-service"
    namespace = "default"
    labels = {
      app = "elasticsearch"
      role = "data"
    }
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-internal": "false"
    }
  }

  spec {
    selector = {
      app = "elasticsearch"
      role = "data"
    }
    port {
      name        = "rest-port"
      port        = 9200
      target_port = 9200
      protocol    = "TCP"
    }
    
    port {
      name        = "node-port"
      port        = 9300
      target_port = 9300
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}

################
#### Kibana ####
################

resource "kubernetes_deployment" "kibana_dep" {
  
  metadata {
    name = "kibana-dep"
    namespace = "default"
    labels = {
      app  = "kibana"
      role = "data"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kibana"
      }
    }

    template {
      metadata {
        labels = {
          app  = "kibana"
          role = "data"
        }
      }

      spec {
        container {
          image = "docker.elastic.co/kibana/kibana:7.6.1"
          name  = "kibana"
          image_pull_policy = "Always"

          env {
            name  = "XPACK_INFRA_SOURCES_DEFAULT_LOGALIAS"
            value = "filebeat-*,kibana_sample_data_logs*,logstash-*"
          }

          env {
            name  = "CLUSTER_NAME"
            value = "elasticsearch-cluster"
          }

          env {
            name  = "ELASTICSEARCH_HOSTS"
            value = "http://elasticsearch-service:9200"
          }

          env {
            name  = "LOGGING_QUIET"
            value = "true"
          }

          env {
            name  = "ELASTICSEARCH_REQUESTTIMEOUT"
            value = "300000"
          }

          env {
            name  = "ELASTICSEARCH_SHARDTIMEOUT"
            value = "300000"
          }

          port {
            container_port = 5601
            name = "http"
            protocol = "TCP"
          }
        }
        termination_grace_period_seconds = 10
      }
    }
  }
}

resource "kubernetes_service" "kibana_service" {

  metadata {
    name = "kibana-service"
    namespace = "default"
    labels = {
      app = "kibana"
      role = "data"
    }
  }

  spec {
    selector = {
      app = "kibana"
      role = "data"
    }
    port {
      port        = 5601
      target_port = 5601
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}

##################
#### Logstash ####
##################

resource "kubernetes_config_map" "logstash_cm" {
  
  metadata {
    name = "logstash-configmap"
    namespace = "default"
    labels = {
      app = "logstash"
      role = "data"
    }
  }

  data = {
    "logstash.yml" = file("${path.module}/logstash.yml")
    "logstash.conf" = file("${path.module}/logstash.conf")
  }
}

resource "kubernetes_deployment" "logstash_dep" {
  
  metadata {
    name = "logstash-dep"
    namespace = "default"
    labels = {
      app = "logstash"
      role = "data"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "logstash"
        role = "data"
      }
    }

    template {
      metadata {
        labels = {
          app = "logstash"
          role = "data"
        }
      }

      spec {
        restart_policy = "Always"
        container {
          image = "docker.elastic.co/logstash/logstash:7.8.0"
          name  = "logstash"
          image_pull_policy = "Always"

          env {
            name  = "ES_HOSTS"
            value = "http://elasticsearch-service:9200"
          }

          env {
            name  = "LOGGING_BUCKET"
            value = var.s3_log_bucket
          }

          env {
            name  = "AWS_REGION"
            value = var.region
          }

          env {
            name  = "PRIMARY_AWS_REGION"
            value = var.prim_region
          }

          env {
            name  = "FAILOVER_AWS_REGION"
            value = var.fail_region
            
          }

          port {
            container_port = 25826
            name = "port25826"
            protocol = "TCP"
          }

          port {
            container_port = 5044
            name = "port5044"
            protocol = "TCP"
          }

          volume_mount {
            name       = "config-volume"
            mount_path = "/usr/share/logstash/config"
          }

          volume_mount {
            name       = "logstash-pipeline-volume"
            mount_path = "/usr/share/logstash/pipeline"
            read_only   = true
          }
        }
        termination_grace_period_seconds = 10
        volume {
          name = "config-volume"

          config_map {
            name = "logstash-configmap"
            items {
              key = "logstash.yml"
              path = "logstash.yml"
            }
          }
        }
        volume {
          name = "logstash-pipeline-volume"

          config_map {
            name = "logstash-configmap"
            items {
              key = "logstash.conf"
              path = "logstash.conf"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "logstash_service" {

  metadata {
    name = "logstash-service"
    namespace = "default"
    labels = {
      app = "logstash"
      role = "data"
    }
  }

  spec {
    selector = {
      app = "logstash"
      role = "data"
    }
    session_affinity = "ClientIP"
    port {
      name        = "25826"
      port        = 25826
      target_port = 25826
      protocol    = "TCP"
    }
    
    port {
      name        = "5044"
      port        = 5044
      target_port = 5044
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
