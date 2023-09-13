input_prefix="fp"
input_project = "trf-learning"
input_region = "europe-west8"
create_instance = false
vm_counter = ["0", "1", "2"]
tf_vms = {
    fp_vm_0 = {
        suffix_name  = "0"
        machine_type = "n2-standard-2"
  },
    fp_vm_1 = {
        suffix_name  = "1"
        machine_type = "n2-standard-2"
  },
    fp_vm_2 = {
        suffix_name  = "2"
        machine_type = "n2-standard-2"
  }
}