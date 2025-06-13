@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Shopping Cart'
@ObjectModel.sapObjectNodeType.name: 'ZGE187815'
define root view entity ZR_GE187815
  as select from zge187815 as ShoppingCart
{
  key order_uuid              as OrderUuid,
      order_id                as OrderId,
      ordered_item            as OrderedItem,
      order_quantity          as OrderQuantity,
      requested_delivery_date as RequestedDeliveryDate,
      @Semantics.amount.currencyCode: 'Currency'
      total_price             as TotalPrice,
      @Consumption.valueHelpDefinition: [ {
        entity.name: 'I_CurrencyStdVH',
        entity.element: 'Currency',
        useForValidation: true
      } ]
      currency                as Currency,
      overall_status          as OverallStatus,
      sales_order_status      as SalesOrderStatus,
      salesorder              as Salesorder,
      bgpf_status             as BgpfStatus,
      bgpg_process_name       as BgpgProcessName,
      manage_sales_order_url  as ManageSalesOrderUrl,
      notes                   as Notes,
      @Semantics.user.createdBy: true
      created_by              as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at              as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by         as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at         as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at   as LocalLastChangedAt

}
