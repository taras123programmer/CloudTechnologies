data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag and its value on resources"
}

resource "azurerm_resource_group_policy_assignment" "cost_center" {
  name                 = "RequireCostCenterTag"
  resource_group_id    = azurerm_resource_group.rg2.id
  policy_definition_id = data.azurerm_policy_definition.require_tag.id
  description          = "Require Cost Center tag and its value on all resources in the resource group"

  parameters = jsonencode({
    tagName  = { value = "Cost Center" }
    tagValue = { value = "000" }
  })
}