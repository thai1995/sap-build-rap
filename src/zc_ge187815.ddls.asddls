@Metadata.allowExtensions: true
@EndUserText.label: 'Online Shop'
@AccessControl.authorizationCheck: #CHECK
@ObjectModel.sapObjectNodeType.name: 'ZGE187815'
@Search.searchable: true
@ObjectModel.semanticKey: ['OrderId']
define root view entity ZC_GE187815
  provider contract transactional_query
  as projection on ZR_GE187815
{
  key OrderUuid,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90
      OrderId,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90
      @Consumption.valueHelpDefinition: [ {
        entity.name: 'ZI_VH_PRODUCTS',
        entity.element: 'Product',
        useForValidation: true
        } ]
      OrderedItem,
      OrderQuantity,
      RequestedDeliveryDate,
      TotalPrice,
      @Semantics.currencyCode: true
      Currency,
      OverallStatus,
      SalesOrderStatus,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90
      Salesorder,
      BgpfStatus,
      BgpgProcessName,
      ManageSalesOrderUrl,
      Notes,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt

}
