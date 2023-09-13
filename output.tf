//output "fp_vm_name" {
//  description = "VM Name"
//  value       = google_compute_instance.fp_vm[*].name
//}
//
output "fp_vm_name" {
    description = "VM Name and IP"
    value = {for _,vm in google_compute_instance.fp_vm: vm.name => vm.network_interface[0].network_ip}
}