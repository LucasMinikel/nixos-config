{ pkgs, ... }:

let
  prometheusPort = 9090;
  nodePort = 9100;
  processPort = 9256;
  systemdPort = 9558;
  smartctlPort = 9633;

  dashboardDir = pkgs.writeTextDir "system-overview.json" (builtins.toJSON {
    uid = "local-system-overview";
    title = "Local system overview";
    schemaVersion = 39;
    version = 1;
    refresh = "10s";
    time = {
      from = "now-6h";
      to = "now";
    };
    tags = [ "nixos" "local" ];
    templating.list = [ ];
    panels = [
      {
        id = 1;
        type = "timeseries";
        title = "CPU usage";
        datasource.uid = "prometheus";
        gridPos = {
          h = 8;
          w = 12;
          x = 0;
          y = 0;
        };
        fieldConfig.defaults = {
          unit = "percent";
          min = 0;
          max = 100;
        };
        targets = [
          {
            refId = "A";
            expr = ''100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'';
            legendFormat = "CPU";
          }
        ];
      }
      {
        id = 2;
        type = "timeseries";
        title = "Memory usage";
        datasource.uid = "prometheus";
        gridPos = {
          h = 8;
          w = 12;
          x = 12;
          y = 0;
        };
        fieldConfig.defaults = {
          unit = "percent";
          min = 0;
          max = 100;
        };
        targets = [
          {
            refId = "A";
            expr = ''(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100'';
            legendFormat = "RAM";
          }
        ];
      }
      {
        id = 3;
        type = "timeseries";
        title = "Network traffic";
        datasource.uid = "prometheus";
        gridPos = {
          h = 8;
          w = 12;
          x = 0;
          y = 8;
        };
        fieldConfig.defaults.unit = "Bps";
        targets = [
          {
            refId = "A";
            expr = ''sum by (device) (rate(node_network_receive_bytes_total{device!~"lo|docker.*|veth.*|br-.*"}[5m]))'';
            legendFormat = "{{device}} rx";
          }
          {
            refId = "B";
            expr = ''sum by (device) (rate(node_network_transmit_bytes_total{device!~"lo|docker.*|veth.*|br-.*"}[5m]))'';
            legendFormat = "{{device}} tx";
          }
        ];
      }
      {
        id = 4;
        type = "timeseries";
        title = "Disk usage";
        datasource.uid = "prometheus";
        gridPos = {
          h = 8;
          w = 12;
          x = 12;
          y = 8;
        };
        fieldConfig.defaults = {
          unit = "percent";
          min = 0;
          max = 100;
        };
        targets = [
          {
            refId = "A";
            expr = ''100 * (1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|overlay|squashfs",mountpoint!~"/run.*"} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|overlay|squashfs",mountpoint!~"/run.*"}))'';
            legendFormat = "{{mountpoint}}";
          }
        ];
      }
      {
        id = 5;
        type = "timeseries";
        title = "Top process groups by CPU";
        datasource.uid = "prometheus";
        gridPos = {
          h = 8;
          w = 12;
          x = 0;
          y = 16;
        };
        fieldConfig.defaults.unit = "percentunit";
        targets = [
          {
            refId = "A";
            expr = "topk(10, sum by (groupname) (rate(namedprocess_namegroup_cpu_seconds_total[5m])))";
            legendFormat = "{{groupname}}";
          }
        ];
      }
      {
        id = 6;
        type = "timeseries";
        title = "Top process groups by memory";
        datasource.uid = "prometheus";
        gridPos = {
          h = 8;
          w = 12;
          x = 12;
          y = 16;
        };
        fieldConfig.defaults.unit = "bytes";
        targets = [
          {
            refId = "A";
            expr = "topk(10, sum by (groupname) (namedprocess_namegroup_memory_bytes))";
            legendFormat = "{{groupname}}";
          }
        ];
      }
      {
        id = 7;
        type = "stat";
        title = "Failed systemd units";
        datasource.uid = "prometheus";
        gridPos = {
          h = 4;
          w = 6;
          x = 0;
          y = 24;
        };
        targets = [
          {
            refId = "A";
            expr = ''sum(node_systemd_unit_state{state="failed"})'';
            legendFormat = "failed";
          }
        ];
      }
      {
        id = 8;
        type = "stat";
        title = "Exporter targets down";
        datasource.uid = "prometheus";
        gridPos = {
          h = 4;
          w = 6;
          x = 6;
          y = 24;
        };
        targets = [
          {
            refId = "A";
            expr = "sum(up == 0)";
            legendFormat = "down";
          }
        ];
      }
    ];
  });
in
{
  services.grafana = {
    enable = true;
    openFirewall = false;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "localhost";
      };
      analytics.reporting_enabled = false;
      security = {
        admin_user = "lucas";
        admin_password = "admin";
        secret_key = "local-nixos-grafana-secret-key-change-before-exposing";
      };
    };
    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        prune = true;
        datasources = [
          {
            name = "Prometheus";
            uid = "prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString prometheusPort}";
            isDefault = true;
            editable = true;
          }
        ];
      };
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "Local dashboards";
            type = "file";
            disableDeletion = false;
            updateIntervalSeconds = 30;
            options.path = dashboardDir;
          }
        ];
      };
    };
  };

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = prometheusPort;
    retentionTime = "30d";
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };
    alertmanagers = [
      {
        scheme = "http";
        static_configs = [
          { targets = [ "127.0.0.1:9093" ]; }
        ];
      }
    ];
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          { targets = [ "127.0.0.1:${toString nodePort}" ]; }
        ];
      }
      {
        job_name = "process";
        static_configs = [
          { targets = [ "127.0.0.1:${toString processPort}" ]; }
        ];
      }
      {
        job_name = "systemd";
        static_configs = [
          { targets = [ "127.0.0.1:${toString systemdPort}" ]; }
        ];
      }
      {
        job_name = "smartctl";
        static_configs = [
          { targets = [ "127.0.0.1:${toString smartctlPort}" ]; }
        ];
      }
    ];
    rules = [
      ''
        groups:
          - name: local-system
            rules:
              - alert: ExporterDown
                expr: up == 0
                for: 2m
                labels:
                  severity: warning
                annotations:
                  summary: "{{ $labels.job }} exporter is down"
              - alert: HighCpuUsage
                expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
                for: 10m
                labels:
                  severity: warning
                annotations:
                  summary: "CPU usage is above 90%"
              - alert: HighMemoryUsage
                expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
                for: 10m
                labels:
                  severity: warning
                annotations:
                  summary: "Memory usage is above 90%"
              - alert: LowDiskSpace
                expr: 100 * (1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|overlay|squashfs",mountpoint!~"/run.*"} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|overlay|squashfs",mountpoint!~"/run.*"})) > 85
                for: 15m
                labels:
                  severity: warning
                annotations:
                  summary: "Filesystem {{ $labels.mountpoint }} is above 85%"
              - alert: FailedSystemdUnit
                expr: node_systemd_unit_state{state="failed"} == 1
                for: 2m
                labels:
                  severity: warning
                annotations:
                  summary: "Systemd unit {{ $labels.name }} failed"
      ''
    ];
    exporters = {
      node = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = nodePort;
        enabledCollectors = [ "systemd" ];
      };
      process = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = processPort;
        settings.process_names = [
          {
            name = "{{.Comm}}";
            cmdline = [ ".+" ];
          }
        ];
      };
      systemd = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = systemdPort;
      };
      smartctl = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = smartctlPort;
      };
    };
  };

  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9093;
    configuration = {
      route = {
        receiver = "local";
        group_by = [ "alertname" "instance" ];
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "12h";
      };
      receivers = [
        { name = "local"; }
      ];
    };
  };
}
