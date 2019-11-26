provider "mongodbatlas" {
  public_key = "${var.public_key}"
  private_key = "${var.private_key}"
}
resource "mongodbatlas_project" "aws_atlas" {
    name = "aws_atlas"
  org_id = "5c98a80fc56c98ef210b8633"
}

resource "mongodbatlas_cluster" "cluster-atlas" {
  project_id = "${mongodbatlas_project.aws_atlas.id}"
  name = "cluster-atlas"
  num_shards = 1
  replication_factor = 3
  backup_enabled = true
  auto_scaling_disk_gb_enabled = true
  mongo_db_major_version  = "4.0"

  //Provider settings
  provider_name = "AWS"
  disk_size_gb = 10
  provider_disk_iops = 100
  provider_volume_type = "STANDARD"
  provider_encrypt_ebs_volume = true
  provider_instance_size_name = "M10"
  provider_region_name = "${var.atlas_region}"
  depends_on = ["mongodbatlas_project.aws_atlas"]
}

resource "mongodbatlas_database_user" "db-user" {
  username = "${var.atlas_dbuser}"
  password = "${var.atlas_dbpassword}"
  database_name = "admin"
  project_id = "${mongodbatlas_project.aws_atlas.id}"
  roles{
      role_name = "readWrite"
      database_name = "admin"
  }
  depends_on = ["mongodbatlas_project.aws_atlas"]
}
resource "mongodbatlas_network_container" "atlas_container" {
    atlas_cidr_block = "192.168.248.0/21"
    project_id       = "${mongodbatlas_project.aws_atlas.id}"
    provider_name    = "AWS"
    region_name      = "US_EAST_1"
    }
data "mongodbatlas_network_container" "atlas_container" {
    container_id = "${mongodbatlas_network_container.atlas_container.container_id}"
    project_id = "${mongodbatlas_project.aws_atlas.id}"
    }


resource "mongodbatlas_network_peering" "aws-atlas" {
  accepter_region_name   = "us-west-2"
  project_id             = "${mongodbatlas_project.aws_atlas.id}"
  container_id           = "${mongodbatlas_network_container.atlas_container.container_id}"
  provider_name          = "AWS"
  route_table_cidr_block = "10.0.0.0/16"
  vpc_id                 = "${aws_vpc.primary.id}"
  aws_account_id         = "208629369896"
}


