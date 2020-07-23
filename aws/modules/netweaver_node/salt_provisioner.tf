resource "null_resource" "netweaver_provisioner" {
  count = var.common_variables["provisioner"] == "salt" ? var.netweaver_count : 0

  triggers = {
    netweaver_id = join(",", aws_instance.netweaver.*.id)
  }

  connection {
    host        = element(aws_instance.netweaver.*.public_ip, count.index)
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_location)
  }

  provisioner "file" {
    source      = var.aws_access_key_id == "" || var.aws_secret_access_key == "" ? var.aws_credentials : "/dev/null"
    destination = "/tmp/credentials"
  }

  provisioner "file" {
    content     = <<EOF
role: netweaver_node
${var.common_variables["grains_output"]}
region: ${var.aws_region}
name_prefix: ${var.name}
hostname: ${var.name}0${count.index + 1}
aws_cluster_profile: Cluster
aws_instance_tag: ${terraform.workspace}-cluster
aws_credentials_file: /tmp/credentials
aws_access_key_id: ${var.aws_access_key_id}
aws_secret_access_key: ${var.aws_secret_access_key}
route_table: ${var.route_table_id}
network_domain: ${var.network_domain}
host_ips: [${join(", ", formatlist("'%s'", var.host_ips))}]
virtual_host_ips: [${join(", ", formatlist("'%s'", var.virtual_host_ips))}]
host_ip: ${element(var.host_ips, count.index)}
cluster_ssh_pub:  ${var.cluster_ssh_pub}
cluster_ssh_key: ${var.cluster_ssh_key}
ha_enabled: ${var.ha_enabled}
sbd_enabled: ${var.sbd_enabled}
sbd_storage_type: ${var.sbd_storage_type}
sbd_lun_index: 1
iscsi_srv_ip: ${var.iscsi_srv_ip}
ascs_instance_number: ${var.ascs_instance_number}
ers_instance_number: ${var.ers_instance_number}
pas_instance_number: ${var.pas_instance_number}
aas_instance_number: ${var.aas_instance_number}
netweaver_product_id: ${var.netweaver_product_id}
netweaver_inst_folder: ${var.netweaver_inst_folder}
netweaver_extract_dir: ${var.netweaver_extract_dir}
netweaver_swpm_folder: ${var.netweaver_swpm_folder}
netweaver_sapcar_exe: ${var.netweaver_sapcar_exe}
netweaver_swpm_sar: ${var.netweaver_swpm_sar}
netweaver_sapexe_folder: ${var.netweaver_sapexe_folder}
netweaver_additional_dvds: [${join(", ", formatlist("'%s'", var.netweaver_additional_dvds))}]
netweaver_nfs_share: "${var.netweaver_nfs_share}"
netweaver_inst_disk_device: /dev/xvdd
hana_ip: ${var.hana_ip}
s3_bucket: ${var.s3_bucket}
  EOF
    destination = "/tmp/grains"
  }
}

module "netweaver_provision" {
  source               = "../../../generic_modules/salt_provisioner"
  node_count           = var.common_variables["provisioner"] == "salt" ? var.netweaver_count : 0
  instance_ids         = null_resource.netweaver_provisioner.*.id
  user                 = "ec2-user"
  private_key_location = var.common_variables["private_key_location"]
  public_ips           = aws_instance.netweaver.*.public_ip
  background           = var.common_variables["background"]
}
