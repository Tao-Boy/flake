{
  virtualisation.oci-containers.backend = "podman";

  # 系统容器的镜像与可写层统一存放在 /var，工作区由各服务单独挂载。
  virtualisation.containers.storage.settings.storage.graphroot = "/var/lib/containers/storage";
}
