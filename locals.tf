locals {
  domain      = format("hive-metastore.%s", trimprefix("${var.subdomain}.${var.base_domain}", "."))
  domain_full = format("hive-metastore.%s.%s", trimprefix("${var.subdomain}.${var.cluster_name}", "."), var.base_domain)

  helm_values = [{
    image = {
      repository = "sslhep/hive-metastore"
      pullPolicy = "IfNotPresent"
      tag        = "3.1.3"
    }
    serviceAccount = {
      create = true
    }
    service = {
      type = "ClusterIP"
      port = 9083
    }
    # Exposure is handled by the HTTPRoute below, served by the Istio gateway,
    # so the chart's own Ingress stays disabled.
    ingress = {
      enabled = false
    }
    resources = {
      requests = { for k, v in var.resources.requests : k => v if v != null }
      limits   = { for k, v in var.resources.limits : k => v if v != null }
    }
    connections = {
      database = {
        # password = "hive"
        username = "${var.database.user}hive"
        password = "${var.database.password}"
        database = "${var.database.database}"
        host     = "${var.database.service}"
        port     = 5432
      }
    }
    conf = {
      hiveSite = {
        "hive.metastore.warehouse.dir"          = "s3a://warehouse/metastore"
        "javax.jdo.option.ConnectionDriverName" = "org.postgresql.Driver"
      }
    }
    objectStore = {
      sslEnabled      = false
      endpoint        = "http://${var.storage.endpoint}"
      accessKeyId     = "${var.storage.access_key}"
      secretAccessKey = "${var.storage.secret_access_key}"
      pathStyle       = true
      impl            = "org.apache.hadoop.fs.s3a.S3AFileSystem"
    }
    log = {
      level = {
        meta           = "debug"
        hive           = "debug"
        datanucleusorg = "debug"
        datanucleus    = "debug"
        root           = "debug"
      }
    }
    postgresql = {
      enabled = false
      primary = {
        persistence = {
          enabled      = false
          storageClass = "standard"
        }
      }
    }
  }]

  helm_values_httproute = [{
    httproute = {
      enabled           = true
      host              = local.domain
      gateway_name      = var.gateway_name
      gateway_namespace = var.gateway_namespace
    }
  }]
}
