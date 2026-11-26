output "postes" {
  value = { for p in local.liste : p.nom => "${p.ip} (${local.region_de[p.nom]})" }
}

output "fichiers" {
  value = "Identifiants : identifiants.csv et fiches.html (à imprimer, ne pas projeter)"
}
