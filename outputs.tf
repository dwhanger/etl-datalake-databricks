/*
output "zzzzz_eventgrid_dynatrace_to_run_after_deploy" {
  value = "az eventgrid event-subscription create --name EndPointCheckerDynatrace --endpoint 'https://${azurerm_function_app.func_app_uw.default_hostname}/runtime/webhooks/EventGrid?functionName=EndPointTypeDynatrace' --endpoint-type webhook --subject-begins-with Dynatrace --subject-case-sensitive false --event-delivery-schema eventgridschema --labels functions-endpointtypedynatrace --source-resource-id '/subscriptions/${var.subscriptionid}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.EventGrid/topics/${azurerm_eventgrid_topic.eventgrid.name}' --subscription ${var.subscriptionid}"
}

output "zzzzz_eventgrid_http_to_run_after_deploy" {
  value = "az eventgrid event-subscription create --name EndPointCheckerHttp --endpoint 'https://${azurerm_function_app.func_app_uw.default_hostname}/runtime/webhooks/EventGrid?functionName=EndPointTypeHttp' --endpoint-type webhook --subject-begins-with Http --subject-case-sensitive false --event-delivery-schema eventgridschema --labels functions-endpointtypehttp --source-resource-id '/subscriptions/${var.subscriptionid}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.EventGrid/topics/${azurerm_eventgrid_topic.eventgrid.name}' --subscription ${var.subscriptionid}"
}

*/
